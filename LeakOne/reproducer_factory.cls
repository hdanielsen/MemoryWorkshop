block-level on error undo, throw.

using LeakOne.i_leak_reproducer from propath.
using LeakOne.leak_reproducer from propath.

class LeakOne.reproducer_factory:
  
  method public i_leak_reproducer GetMock(iplInline as logical):
    return new leak_reproducer(iplInline).
  end method.

  method public leak_reproducer GetConcreteMock(iplInline as logical):
    return new leak_reproducer(iplInline).
  end method.

end class.

