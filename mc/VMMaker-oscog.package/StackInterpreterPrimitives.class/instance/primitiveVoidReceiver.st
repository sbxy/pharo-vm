system control primitives
primitiveVoidReceiver
	"Potentially crash the VM by voiding the receiver.  A subsequent inst var
	 access in the caller's frame should indirect through a null pointer."
	<export: true>
	stackPages longAt: (self frameReceiverOffset: framePointer) put: 0