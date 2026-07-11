block-level on error undo, throw.

interface LeakOne.i_leak_reproducer:
  define public property ValueField as handle no-undo set.
end interface.
