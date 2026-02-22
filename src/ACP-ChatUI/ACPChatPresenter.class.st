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

	^ self new agentCommandArguments: #( 'claude' '--acp' )
]

{ #category : 'instance creation' }
ACPChatPresenter class >> gemini [

	^ self new agentCommandArguments: #( 'gemini' '--experimental-acp' )
]

{ #category : 'accessing' }
ACPChatPresenter >> agentCommandArguments: anArray [

	agentCommandArguments := anArray
]

{ #category : 'api' }
ACPChatPresenter >> appendText: aString [

	messageDisplay text: messageDisplay text , aString
]

{ #category : 'api' }
ACPChatPresenter >> appendUserMessage: aString [

	messageDisplay text: messageDisplay text , 'YOU: ' , aString , String lf , String lf
]

{ #category : 'initialization' }
ACPChatPresenter >> connectPresenters [

	sendButton action: [
		| text |
		text := inputField text trimSeparators.
		text isEmpty ifFalse: [
			inputField text: ''.
			self sendMessage: text ] ]
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

{ #category : 'layout' }
ACPChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messageDisplay;
		  add: (SpBoxLayout newLeftToRight
				   add: inputField;
				   add: sendButton width: 70;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'api' }
ACPChatPresenter >> disconnect [

	client ifNotNil: [ client disconnect ]
]

{ #category : 'initialization' }
ACPChatPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable.

	inputField := self newTextInput.
	inputField placeholder: 'Type your message...'.

	sendButton := self newButton.
	sendButton label: 'Send'
]

{ #category : 'initialization' }
ACPChatPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'ACP Chat';
		initialExtent: 640 @ 520.
	aWindowPresenter whenClosedDo: [ self disconnect ]
]

{ #category : 'api' }
ACPChatPresenter >> open [

	self setupClient.
	self connectToAgent.
	super open
]

{ #category : 'agent-callbacks' }
ACPChatPresenter >> requestPermission: anACPRequestPermission [

	^ anACPRequestPermission makeResponse allowAlways
]

{ #category : 'api' }
ACPChatPresenter >> sendMessage: aString [

	self appendUserMessage: aString.
	agentMessageStarted := false.
	[
		client promptBy: [ :params |
			params sessionId: sessionId.
			params textPrompt: aString ].
		UIManager default defer: [ self appendText: String lf , String lf ]
	] fork
]

{ #category : 'agent-callbacks' }
ACPChatPresenter >> sessionUpdate: aSessionUpdate [

	| text |
	aSessionUpdate isAgentMessageChunk ifFalse: [ ^ self ].
	text := aSessionUpdate content text.
	text ifNil: [ ^ self ].
	UIManager default defer: [
		agentMessageStarted ifFalse: [
			self appendText: 'AGENT: '.
			agentMessageStarted := true ].
		self appendText: text ]
]

{ #category : 'private' }
ACPChatPresenter >> setupClient [

	client := ACPClient new.
	client handler: self.
	client agentCommand: '/usr/bin/env' arguments: agentCommandArguments
]

{ #category : 'accessing' }
ACPChatPresenter >> workingDirectory [

	^ workingDirectory ifNil: [ workingDirectory := FileSystem workingDirectory ]
]

{ #category : 'accessing' }
ACPChatPresenter >> workingDirectory: aPathString [

	workingDirectory := aPathString asFileReference
]
