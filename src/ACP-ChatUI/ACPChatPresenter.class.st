Class {
	#name : 'ACPChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageDisplay',
		'inputField',
		'sendButton',
		'client',
		'sessionId',
		'agentCommandArguments',
		'workingDirectory',
		'agentMessageStarted'
	],
	#category : 'ACP-ChatUI',
	#package : 'ACP-ChatUI'
}

{ #category : 'instance creation' }
ACPChatPresenter class >> claude [

	^ self new agentCommandArguments: #( 'claude-code-acp' )
]

{ #category : 'instance creation' }
ACPChatPresenter class >> gemini [

	^ self new agentCommandArguments: #( 'gemini' '--experimental-acp' )
]

{ #category : 'instance creation' }
ACPChatPresenter class >> openCode [

	^ self new agentCommandArguments: #( 'opencode' 'acp' )
]

{ #category : 'accessing' }
ACPChatPresenter >> agentCommandArguments: anArray [

	agentCommandArguments := anArray
]

{ #category : 'accessing' }
ACPChatPresenter >> workingDirectory [

	^ workingDirectory ifNil: [ workingDirectory := FileSystem workingDirectory ]
]

{ #category : 'accessing' }
ACPChatPresenter >> workingDirectory: aPathString [

	workingDirectory := aPathString asFileReference
]

{ #category : 'initialization' }
ACPChatPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable.

	inputField := self newText.
	inputField placeholder: 'Type your message...'.

	sendButton := self newButton.
	sendButton label: 'Send'
]

{ #category : 'initialization' }
ACPChatPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'ACP Chat';
		initialExtent: 640 @ 520.
	aWindowPresenter whenClosedDo: [ [self disconnect] fork ]
]

{ #category : 'initialization' }
ACPChatPresenter >> connectPresenters [

	sendButton action: [
		| text |
		text := inputField text trim.
		text isEmpty ifFalse: [
			inputField text: ''.
			self sendMessage: text ] ].
	self disableInput
]

{ #category : 'layout' }
ACPChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messageDisplay;
		  add: (SpBoxLayout newLeftToRight
				   add: inputField;
				   add: sendButton width: 70;
				   yourself)
		  withConstraints: [ :c | c height: 80 ];
		  yourself
]

{ #category : 'api' }
ACPChatPresenter >> disconnect [

	client ifNotNil: [ client disconnect ]
]

{ #category : 'api' }
ACPChatPresenter >> open [

	[
		self setupClient.
		self connectToAgent.
		self defer: [ self enableInput ]
	] fork.
	super open
]

{ #category : 'api' }
ACPChatPresenter >> appendText: aString [

	messageDisplay text: messageDisplay text , aString
]

{ #category : 'api' }
ACPChatPresenter >> appendUserMessage: aString [

	| prefix |
	prefix := messageDisplay text isEmpty
		          ifTrue: [ '' ]
		          ifFalse: [ String lf , String lf ].
	messageDisplay text: messageDisplay text , prefix , 'YOU: ' , aString , String lf , String lf
]

{ #category : 'api' }
ACPChatPresenter >> sendMessage: aString [

	self appendUserMessage: aString.
	self disableInput.
	agentMessageStarted := false.
	[
		client promptBy: [ :params |
			params sessionId: sessionId.
			params textPrompt: aString ].
		self defer: [
			self appendText: String lf , String lf.
			self enableInput ]
	] fork
]

{ #category : 'agent-callbacks' }
ACPChatPresenter >> sessionUpdate: aSessionUpdate [

	| text |
	(aSessionUpdate isAgentMessageChunk or: [aSessionUpdate isAgentThoughtChunk])
	    ifFalse: [ ^ self ].
	text := aSessionUpdate content text.
	text ifNil: [ ^ self ].
	self defer: [
		agentMessageStarted ifFalse: [
			self appendText: 'AGENT: '.
			agentMessageStarted := true ].
		self appendText: text ]
]

{ #category : 'agent-callbacks' }
ACPChatPresenter >> requestPermission: anACPRequestPermission [

	^ anACPRequestPermission makeResponse allowAlways
]

{ #category : 'private' }
ACPChatPresenter >> enableInput [

	inputField enabled: true.
	sendButton enabled: true
]

{ #category : 'private' }
ACPChatPresenter >> disableInput [

	inputField enabled: false.
	sendButton enabled: false
]

{ #category : 'private' }
ACPChatPresenter >> setupClient [

	client := ACPClient new.
	client handler: self.
	client agentCommand: '/usr/bin/env' arguments: agentCommandArguments
]

{ #category : 'private' }
ACPChatPresenter >> connectToAgent [

	| sessionResult |
	client connect.
	client initialize: ACPInitializeParams new.
	sessionResult := client newSessionBy: [ :params |
		params cwd: self workingDirectory fullName ].
	sessionId := sessionResult sessionId.
	agentMessageStarted := false
]
