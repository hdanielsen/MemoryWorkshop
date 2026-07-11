block-level on error undo, throw.

using System.Collections.Hashtable from assembly.
using LeakOne.i_leak_reproducer from propath.
using LeakOne.leak_reproducer from propath.

class LeakOne.leak_reproducer implements i_leak_reproducer:
  
  define private variable oHash as Hashtable no-undo.
  define private variable lInline as logical no-undo.

  constructor public leak_reproducer(iplInline as logical):
    assign
      oHash = new Hashtable()
      lInline = iplInline.
  end constructor.

  define public property ValueField as handle no-undo
    get:
      return ?.
    end get.
    set(iphVal as handle):
      if lInline then do:
        /* FIXED PATTERN: Inline the assignment instead of calling instance method on this-object */
        oHash:Clear().
        oHash:Add("val", iphVal:buffer-value()).
      end.
      else do:
        /* DELEGATING TO AN INSTANCE METHOD: This triggers the leak! */
        this-object:ProcessValue(iphVal).
      end.
    end set.

  method private void ProcessValue(iphVal as handle):
    oHash:Clear().
    oHash:Add("val", iphVal:buffer-value()).
  end method.

  method public leak_reproducer Self():
    return this-object.
  end method.

  method public static leak_reproducer GetStaticMock(iplInline as logical):
    return new leak_reproducer(iplInline).
  end method.

end class.

