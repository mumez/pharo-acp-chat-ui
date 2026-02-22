Class {
	#name : 'BaselineOfACPChatUI',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfACPChatUI',
	#package : 'BaselineOfACPChatUI'
}

{ #category : 'baseline' }
BaselineOfACPChatUI >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			baseline: 'ACP' with: [ spec repository: 'github://mumez/pharo-acp/src' ];
			package: 'ACP-ChatUI' with: [ spec requires: #( 'ACP' ) ]
	]
]
