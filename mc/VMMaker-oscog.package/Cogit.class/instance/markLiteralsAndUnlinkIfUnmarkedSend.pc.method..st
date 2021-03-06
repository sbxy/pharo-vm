garbage collection
markLiteralsAndUnlinkIfUnmarkedSend: annotation pc: mcpc method: cogMethod
	"Mark and trace literals.  Unlink sends that have unmarked cache tags or targets."
	<var: #mcpc type: #'char *'>
	| literal cacheTag cacheTagMarked entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	annotation = IsObjectReference ifTrue:
		[literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteral: literal].
	(self isSendAnnotation: annotation) ifTrue:
		[cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 cacheTagMarked := objectRepresentation cacheTagIsMarked: cacheTag.
		 objectRepresentation markAndTraceLiteral: cacheTag.
		 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off. sendTable := table].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			(cacheTagMarked not
			 or: [self markAndTraceOrFreeCogMethod: targetMethod firstVisit: targetMethod asUnsignedInteger > mcpc asUnsignedInteger]) ifTrue:
				["Either the cacheTag is unmarked (e.g. new class) or the target
				  has been freed (because it is unmarked) so unlink the send."
				 unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
				 backEnd
					rewriteInlineCacheAt: mcpc asInteger
					tag: targetMethod selector
					target: unlinkedRoutine.
				 codeModified := true.
				 objectRepresentation markAndTraceLiteral: targetMethod selector]]].
	^0 "keep scanning"