 
 /*------------------------------------------------------------------------
    File        : DatasetBuilder
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : hdaniels
    Created     : Fri Sep 11 09:24:05 EDT 2026
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using Pmfo.Core.Manager.IServiceManager from propath.
using Ccs.Common.Application from propath.
using Pmfo.Core.BusinessLogic.IBusinessEntity from propath.
using Pmfo.Util.DatasetUtil from propath.
using Pmfo.Util.TableUtil from propath.
using Pmfo.Util.Array from propath.

block-level on error undo, throw.

class Pmfo.Core.BusinessLogic.DatasetBuilder: 
    
    define protected property ServiceManager as IServiceManager no-undo 
        get():
            return cast(Application:ServiceManager,IServiceManager).
        end.
    
    method public handle CreateExpandDataset(pBe as IBusinessEntity, pcExpand as character):
        define variable hNewDataset      as handle no-undo.
        define variable hOriginalDataset as handle no-undo.
        define variable hTopBuffer       as handle no-undo.
        define variable cResource        as character no-undo.
        define variable i                as integer no-undo.
        define variable cExpand          as character no-undo.
        define variable cEntities        as character extent no-undo.
        define variable hNewBuffer       as handle no-undo.
        
        hOriginalDataset = pBe:datasets[1].
        cResource        = pBe:Resource.
        /* copy tree copies the tree up and down - siblings of the requested table  
          are ingored (also if this it is on top) */ 
        hNewDataset      = DatasetUtil:CopyDatasetTree(hOriginalDataset,cResource, output hNewBuffer).
        
        do i = 1 to num-entries(pcExpand):
            cExpand = entry(i,pcExpand).
            extent(cEntities) = ?.
            cEntities = Array:Split(cExpand, "/").
            CreateRelations(pBE,hNewDataset,hNewBuffer,1,cEntities).      
        end.
        
        return hNewDataset.
        catch e as Progress.Lang.Error :
            if valid-handle(hNewDataSet) then 
                delete object hNewDataset. 
            undo, throw e.      
        end catch.  
    end method.
    
    
    method protected void CreateRelations(pParentBe as IBusinessentity, phNewDataset as handle, phNewParentBuffer as handle, piEntity as integer, pcEntities as character extent):
         define variable oBe             as IBusinessEntity no-undo.
         define variable hNewBuffer      as handle no-undo.
         define variable hOriginalBuffer as handle no-undo.
        
         oBe = ServiceManager:CreateBusinessEntity(pcEntities[piEntity]).
         
         hOriginalBuffer = DatasetUtil:GetTopBuffer(oBe:datasets[1], 1).
         /* It is probably more efficient to create a buffer, but there may currently 
            be code that relies on implied default-buffer-handle when passing table 
            by-reference to get the dataset and relations */
         hNewBuffer = TableUtil:CreateTableLike(hOriginalBuffer):default-buffer-handle.   
         hNewBuffer:serialize-name =  hOriginalBuffer:serialize-name.
         phNewDataset:add-buffer(hNewBuffer).
         phNewDataset:add-relation(phNewParentBuffer, 
                                   hNewBuffer,
                                   oBe:GetJoinPairs(pParentBE),
                                   false, // reposition
                                   true,  // nested
                                   true,  // active - documentation is wrong (says not active)
                                   false, // recursive
                                   true). // foreign keys hidden
         
         if extent(pcEntities) >= piEntity + 1 then
         do:
             CreateRelations(obe,phNewDataset,hNewBuffer,piEntity + 1,pcEntities).       
         end.
         
    end method.  
    
/*    method protected handle CreateTableAndRelation(phNewDataset as handle, phNewParentBuffer as handle,pChildBe as IBusinessentity, pcJoinPairs as character):*/
/*        define variable oBe             as IBusinessEntity no-undo.                                                                                           */
/*        define variable hOriginalBuffer as handle no-undo.                                                                                                    */
/*        define variable hNewBuffer      as handle no-undo.                                                                                                    */
/*                                                                                                                                                              */
/*        hOriginalBuffer = DatasetUtil:GetTopBuffer(pChildBe:datasets[1], 1).                                                                                  */
/*        hNewBuffer = TableUtil:CreateTableLike(hOriginalBuffer):default-buffer-handle.                                                                        */
/*        hNewBuffer:serialize-name =  hOriginalBuffer:serialize-name.                                                                                          */
/*        phNewDataset:add-buffer(hNewBuffer).                                                                                                                  */
/*        phNewDataset:add-relation(phNewParentBuffer, hNewBuffer ,pcJoinPairs,false,true,true,false,true).                                                     */
/*                                                                                                                                                              */
/*        return hNewBuffer.                                                                                                                                    */
/*    end method.                                                                                                                                               */
                  
    
    method protected handle CopyDataset(phDataset as handle, pcRequestedEntity as character, output phbuffer as handle):
        define variable hOriginalBuffer as handle no-undo.
       
        define variable hNewDataset     as handle no-undo.
        create dataset hNewDataset.
        hNewDataset:serialize-name = phDataset:serialize-name.
        hOriginalBuffer = DatasetUtil:GetBufferBySerializeName(phDataset,pcRequestedEntity).  
       
         /* top buffer from this dataset */
        //create buffer phbuffer for table hOriginalBuffer buffer-name hOriginalBuffer:table-handle:name.
        phBuffer = TableUtil:CreateTableLike(hOriginalBuffer):default-buffer-handle.   
        phbuffer:serialize-name =  hOriginalBuffer:serialize-name.
        hNewDataset:add-buffer(phbuffer).
        DatasetUtil:CloneParentRelation(hNewDataset, phbuffer, hOriginalBuffer).
        
        DatasetUtil:CloneChildRelations(hNewdataset, phbuffer, hOriginalBuffer).
        
        return hNewDataset. 
        catch e as Progress.Lang.Error :
           if valid-object(hNewDataset) then 
               delete object hNewDataset.
           undo, throw e.      
        end catch.
        
    end method.
      
end class.