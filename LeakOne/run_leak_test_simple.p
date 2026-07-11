block-level on error undo, throw.

using LeakOne.reproducer_factory from propath.
using LeakOne.leak_reproducer from propath.

/* Set up dummy field handle */
define temp-table ttTest no-undo
  field fChar as character.

create ttTest.
ttTest.fChar = "Test".

define variable hField as handle no-undo.
define variable oFactory as reproducer_factory no-undo.
define variable rObj as Progress.Lang.Object no-undo.
define variable iCount as integer no-undo.
define variable iPass as integer no-undo.
define variable cTestName as character no-undo.
define variable iStartCount as integer no-undo.
define variable iEndCount as integer no-undo.
define variable iLeaked as integer no-undo.

hField = temp-table ttTest:default-buffer-handle:buffer-field("fChar").
oFactory = new reproducer_factory().

/* Run seven distinct scenarios */
do iPass = 1 to 7:
  
  /* Make sure memory is completely clean before starting the pass */
  System.GC:Collect().
  System.GC:WaitForPendingFinalizers().
  System.GC:Collect().

  /* Measure starting instances in session */
  iStartCount = 0.
  rObj = session:first-object.
  do while valid-object(rObj):
    if rObj:GetClass():TypeName = "leak_reproducer" then
      iStartCount = iStartCount + 1.
    rObj = rObj:next-sibling.
  end.
  
  case iPass:
    when 1 then do:
      cTestName = "1. Direct instantiation ((new leak_reproducer(false)):ValueField = hField)".
      do iCount = 1 to 10:
        (new leak_reproducer(false)):ValueField = hField.
      end.
    end.
    when 2 then do:
      cTestName = "2. Chained static method, INLINE mode (leak_reproducer:GetStaticMock(true):ValueField = hField)".
      do iCount = 1 to 10:
        leak_reproducer:GetStaticMock(true):ValueField = hField.
      end.
    end.
    when 3 then do:
      cTestName = "3. Chained static method, DELEGATING mode (leak_reproducer:GetStaticMock(false):ValueField = hField)".
      do iCount = 1 to 10:
		leak_reproducer:GetStaticMock(false):ValueField = hField.
      end.
    end.
    when 4 then do:
      cTestName = "4. Chained instance method (Self returning this-object), DELEGATING mode ((new leak_reproducer(false)):Self():ValueField = hField)".
      do iCount = 1 to 10:
        (new leak_reproducer(false)):Self():ValueField = hField.
      end.
    end.
    when 5 then do:
      cTestName = "5. Chained instance method (factory returning concrete), INLINE mode (oFactory:GetConcreteMock(true):ValueField = hField)".
      do iCount = 1 to 10:
        oFactory:GetConcreteMock(true):ValueField = hField.
      end.
    end.
    when 6 then do:
      cTestName = "6. Chained instance method (factory returning concrete), DELEGATING mode (oFactory:GetConcreteMock(false):ValueField = hField)".
      do iCount = 1 to 10:
        oFactory:GetConcreteMock(false):ValueField = hField.
      end.
    end.
    when 7 then do:
      cTestName = "7. Chained instance method (factory returning interface), DELEGATING mode (oFactory:GetMock(false):ValueField = hField)".
      do iCount = 1 to 10:
        oFactory:GetMock(false):ValueField = hField.
      end.
    end.
  end case.

  /* Force garbage collection to clean up unpinned objects */
  System.GC:Collect().
  System.GC:WaitForPendingFinalizers().
  System.GC:Collect().

  /* Count remaining instances in session */
  iEndCount = 0.
  rObj = session:first-object.
  do while valid-object(rObj):
    if rObj:GetClass():TypeName = "leak_reproducer" then
      iEndCount = iEndCount + 1.
    rObj = rObj:next-sibling.
  end.

  /* Delta is the number of newly leaked objects */
  iLeaked = iEndCount - iStartCount.

  message substitute("&1~n-> Newly Leaked instances: &2", cTestName, iLeaked)
    view-as alert-box.
end.

quit.

