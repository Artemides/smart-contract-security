object "ERC721"{
    code {
        mstore(0x40,0x80)
        //execute constructor
        decodeString(0x0, 0x0)
        decodeString(0x1, 0x1)
        //deploy runtime code on-chain
        datacopy(0,dataoffset("runtime"),datasize("runtime"))
        return(0,datasize("runtime"))

        function decodeString(offset, s_slot){
            let codelen := datasize("ERC721")
            let str_offset_at := add(codelen, mul(offset,0x20))
            let pointer := mload(0x40)
    
            datacopy(pointer, str_offset_at, 0x20)
            let str_offset := mload(pointer)

            let str_len_at :=  add(codelen, str_offset)
            datacopy(pointer, str_len_at, 0x20)
            let str_len := mload(pointer)
            
            pointer := add(pointer,0x20)
            datacopy(pointer, add(str_len_at, 0x20), str_len)
                       
            if gt(str_len, 0x1f) {
                // hash slot
                mstore(0x0, s_slot) 
                let pointer_slot := keccak256(0x0,0x20)
                // store pointer at slot
                sstore(s_slot, pointer_slot)
                // store len at pointer
                sstore(pointer_slot, str_len)
                // store data in 32 bytes chunk
                let slot := add(pointer_slot, 1)
                let limit := add(pointer, str_len)
                let module := mod(limit, 0x20)
                // make limit 0x20 bytes compatible
                if gt(module, 0){
                    limit := add(limit, sub(0x20, module))
                } 
                
                for { let i := pointer } lt(i, limit) { i := add(i, 0x20) } {
                    let chunk := mload(i)
                    sstore(slot, chunk)
    
                    slot := add(slot, 1)
                }
            }
            // store str with len
            if lt(str_len, 32){
                let str := or(mload(pointer), str_len)
                sstore(s_slot, str)
            }
        }

        function lte(a, b) -> r {
            r := iszero(gt(a, b))
        }

    }
    object "runtime" {
        code {
            /** Function Hub/Switcher/Disptacher */
            mstore(0x40,0x80)

            switch selector() 
            /** name() */
            case 0x06fdde03{   
                nameWrapper()
            }
            /** symbol() */ 
            case 0x95d89b41{
                symbolWrapper()
            }
            /** supportsInterface(bytes4)*/
            case 0x01ffc9a7 {
            }
            /** balanceOf(address)*/ 
            case 0x70a08231 {
                balanceOfWrapper()
            }
            /** isApprovedForAll(address, address )*/
            case 0xe985e9c5 {
                isApprovedForAllWrapper()
            }
            /** mint(address,uint256)*/ 
            case 0x40c10f19 { 
                mintWrapper() 
            }
            /** ownerOf(uint256)*/
            case 0x6352211e { 
                ownerOfWrapper() 
            }
            /** getApproved(uint256)*/
            case 0x081812fc {
                getApprovedWrapper()
            }
            /** approve(address,uint256) */
            case 0x095ea7b3 {
                approveWrapper()
            }
            /** setApprovalForAll(address,bool) */
            case 0xa22cb465 {
                setApprovalForAllWrapper()
            }
            /** safeTransferFrom(address,address,uint256) */
            case 0x42842e0e {
                safeTransferFromWrapper()
            }
            /** safeTransferFrom(address,address,uint256,bytes) */
            case 0xb88d4fde {
                safeTransferFromWithDataWrapper()
            }
            /** safeMint(address,uint256) */
            case  0xa1448194 {
                safeMintWrapper()
            }
            /** safeMint(address,uint256,bytes) */
            case 0x8832e6e3{
                safeMintWithDataWrapper()
            }
            /** burn(uint256) */
            case 0x42966c68 {
                burnWrapper()
            }
            default { revert(0,0) }

            /** Function Wrappers / Public */
            function nameWrapper(){
                let nameAt := handleStorageString(_nameSlot())
                let nameLen := make0x20Compatible(mload(nameAt))
                mstore(0x60, 0x20)
                return(0x60, add(0x40, nameLen))
            }

            function symbolWrapper(){
                let  nameAt := handleStorageString(_symbolSlot())
                let  nameLen := mload(nameAt)
                return(nameAt,add(0x20, nameLen))
            }

            function balanceOfWrapper(){
                let bal := _balanceOf(decodeAddress(0))
                returnUint(bal)
            }

            function mintWrapper(){
               let to := decodeAddress(0)
               let tokenId := decodeUint(1)
               _mint(to,tokenId)
            }

            function isApprovedForAllWrapper(){
                let owner := decodeAddress(0)
                let operator := decodeAddress(1)
                let approved := isApprovedForAll(owner,operator)
                if approved {
                    returnUint(1)
                }
        
                returnUint(0)
            }

            function ownerOfWrapper(){
                let tokenId :=decodeUint(0)
                let owner := _requireOwned(tokenId)
                returnUint(owner)
            }      

            function getApprovedWrapper(){
                let tokenId := decodeUint(0)
                let owner := _requireOwned(tokenId)
                let approved := _getApproved(tokenId)
                returnUint(approved)
            }

            function approveWrapper(){
                let to := decodeAddress(0)
                let tokenId := decodeUint(1)
                _approve(to, tokenId, caller(), 0x1)
            }

            function setApprovalForAllWrapper(){
                let operator := decodeAddress(0)
                let approved := decodeBool(1)
                _setApprovalForAll(caller(), operator, approved)
            }

            function transferFromWrapper(){
                let from := decodeAddress(0)
                let to := decodeAddress(1)
                let tokenId := decodeUint(2)
                _transferFrom(from, to, tokenId)
            }
            
            function safeTransferFromWrapper(){
                let from := decodeAddress(0)
                let to := decodeAddress(1)
                let tokenId := decodeAddress(2)
                safeTransferFrom(from,to,tokenId,0)
            }
            function safeTransferFromWithDataWrapper(){
                let from := decodeAddress(0)
                let to := decodeAddress(1)
                let tokenId := decodeAddress(2)
                safeTransferFrom(from,to,tokenId,0x1)
            }

            function safeMintWrapper(){
                let from := decodeAddress(0)
                let tokenId := decodeAddress(1)
                _safeMint(from, tokenId,0x0)
            }

            function safeMintWithDataWrapper(){
                let from := decodeAddress(0)
                let tokenId := decodeUint(1)
                _safeMint(from, tokenId,0x1)
            }

            function burnWrapper(){
                let tokenId := decodeUint(0)
                _burn(tokenId)
            }

            /** Internal Function  */
            function _mint(to,tokenId){
                if iszero(to){
                    revertERC721InvalidReceiver(0x0)
                }

                let oldOwner := _update(to,tokenId,0x0)
                if notZeroAddress(oldOwner) {
                    revertERC721InvalidSender(0x0)
                }
            }

            function _balanceOf(owner)->bal{
                if iszero(owner) {
                    revertERC721InvalidOwner(owner)
                }

                bal := sload(_mapping(owner,_ownersSlot()))
            }

            function _requireOwned(tokenId) -> owner{
                owner := _ownerOf(tokenId)
                if iszero(owner) {
                    revertERC721NonexistentToken(tokenId)
                }
            }

            function _ownerOf(tokenId) -> owner{
                owner := sload(_mapping(tokenId,_ownersSlot()))                
            }

            function _update(to,tokenId,auth) -> from{
                from := _ownerOf(tokenId)
                if notZeroAddress(auth){
                    _checkAuthorized(from,auth,tokenId)
                }

                if notZeroAddress(from){
                    _approve(0x0,tokenId,0x0,0x0)
                    let slot := _mapping(from,_balancesSlot())
                    let prev := sload(slot)
                    sstore(slot, sub(prev,1))
                }

                if notZeroAddress(to){
                    let slot := _mapping(to,_balancesSlot())
                    let prev := sload(slot)
                    sstore(slot,add(prev,1))
                }

                let slot := _mapping(tokenId,_ownersSlot())
                sstore(slot,to)
                emitTransfer(from,to,tokenId)
                //return
            }
      
            function _approve(to, tokenId, auth, emit){
                if or(emit, notZeroAddress(auth)){
                    let owner := _requireOwned(tokenId)

                    if and(notZeroAddress(auth), and(not(eq(owner,auth)), not(isApprovedForAll(owner,auth)))){
                        revertERC721InvalidApprover(auth)
                    }

                    if emit {
                        emitApproval(owner,to,tokenId)
                    }
                }

                let slot := _mapping(tokenId,_tokenApprovalsSlot())
                sstore(slot,to)
            }

            function _checkAuthorized(owner,spender,tokenId){
                if iszero(_isAuthorized(owner,spender,tokenId)){
                    if iszero(owner){
                        revertERC721NonexistentToken(tokenId)
                    }

                    revertERC721InsufficientApproval(spender,tokenId)   
                }
            }

            function _isAuthorized(owner,spender,tokenId) -> authorized{
                let nonZeroSpender := notZeroAddress(spender)
                let selfAuth := eq(owner, spender)
                let approvedForAll := isApprovedForAll(owner, spender)
                let spenderApproved := eq(_getApproved(tokenId), spender)
                authorized := and(nonZeroSpender, or(selfAuth,or(approvedForAll, spenderApproved)))

            }

            function isApprovedForAll(owner, operator) -> approved {
                let slot := _mapping(operator,_mapping(owner,_operatorApprovalsSlot()))
                approved := sload(slot)
            }

            function _getApproved(tokenId) -> approved {
                let slot := _mapping(tokenId,_tokenApprovalsSlot())
                approved := sload(slot)
            }

            function _setApprovalForAll(owner, operator, approved){
                if iszero(operator){
                    revertERC721InvalidOperator(operator)
                }

               let slot := _mapping(operator,_mapping(owner,_operatorApprovalsSlot()))
               sstore(slot,approved)
               emitApprovalForAll(owner,operator,approved)
            }
            function safeTransferFrom(from,to,tokenId,attach){
                _transferFrom(from,to,tokenId)
                _checkOnERC721Received(from,to,tokenId,attach)
            }

            function _transferFrom(from, to, tokenId){
                if iszero(to){
                    revertERC721InvalidReceiver(to)
                }

                let prevOwner := _update(to,tokenId,caller())
                if ne(prevOwner, from){
                    revertERC721IncorrectOwner(from,tokenId,prevOwner)
                }
   
            }

            function _safeMint(to, tokenId, attach){
                _mint(to,tokenId)
                _checkOnERC721Received(0x0, to, tokenId, attach)
            }

            function _burn(tokenId){
                let prevOwner := _update(0x0, tokenId, 0x0)
                if iszero(prevOwner){
                    revertERC721NonexistentToken(tokenId)
                }
            }

            function _checkOnERC721Received(from, to, tokenId,attach){
                if gt(extcodesize(to), 0){
                    
                    let pointer := mload(0x40)
                    mstore(pointer, 0x150b7a02)
                    mstore(add(pointer, 0x20), caller())
                    mstore(add(pointer, 0x40), from)
                    mstore(add(pointer, 0x60), tokenId)
                    mstore(add(pointer, 0x80), 0x80)

                    let bytesAt, bytesSize
                    if attach {
                        mstore(0x40, add(pointer, 0xa0))
                        bytesAt, bytesSize := decodeBytes(3)
                    }

                    if iszero(attach){
                        bytesSize := 0x20
                    }
             

                    let size := add(add(4, mul(4, 0x20)), bytesSize)
                    let success := call(
                            gas(), 
                            to, 
                            0, 
                            add(pointer, 0x1c),
                            size, 
                            0, 
                            0x20
                        )

                    //restore mem pointer, crafted call params won't be useful then
                    mstore(0x40, pointer)
                    if iszero(success) {
                        if iszero(returndatasize()){
                            revertERC721InvalidReceiver(to)
                        }

                        revert(0x20, returndatasize())
                    }

                    returndatacopy(0, 0, returndatasize())

                    let response := mload(0)
                    if ne(response, shl(224,0x150b7a02)){
                        revertERC721InvalidReceiver(to)
                    }
                }
            }
     
            /** Contract Layout  */
            
            function _nameSlot() ->s { s:=0 }
            function _symbolSlot() ->s { s:=1 }
            function _ownersSlot() ->s { s:=2 }
            function _balancesSlot() ->s { s:=3 }
            function _tokenApprovalsSlot() ->s { s:=4 }
            function _operatorApprovalsSlot() ->s { s:=5 } 

             /** Contract Events  */
            
            function emitTransfer(from,to,tokenId){
                let sigHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                
                emitEvent(sigHash,from,to,tokenId)
            }
            function emitApproval(owner,to,tokenId){
                let sigHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925

                emitEvent(sigHash,owner,to,tokenId)
            }

            function emitApprovalForAll(owner,operator,approved){
                let sigHash := 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31

                emitEvent(sigHash,owner,operator,approved)
            }
            
            function emitEvent(sigHash, indexed1, indexed2, nonIndexed){
                mstore(0,nonIndexed)
                log3(0,0x20,sigHash,indexed1,indexed2)
            }

            /** Contract Errors  */

            function revertERC721InvalidOwner(owner){
                mstore(0,0x89c62b64)
                mstore(0x20,owner)
                revert(0x1c,0x24)
            }

            function revertERC721NonexistentToken(tokenId){
                mstore(0,0x7e273289)
                mstore(0x20,tokenId)
                revert(0x1c,0x24)
            }

            function revertERC721InsufficientApproval(spender,tokenId){
                mstore(0,0x177e802f)
                mstore(0x20,spender)
                mstore(0x40,tokenId)
                revert(0x1c,0x44)
            }

            function revertERC721InvalidApprover(approver){
                mstore(0,0xa9fbf51f)
                mstore(0x20,approver)
                revert(0x1c,0x24)
            }

            function revertERC721InvalidReceiver(receiver){
                mstore(0,0x64a0ae92)
                mstore(0x20,receiver)
                revert(0x1c,0x24)
            }
            function revertERC721InvalidSender(sender){
                mstore(0,0x73c6ac6e)
                mstore(0x20,sender)
                revert(0x1c,0x24)
            }

            function revertERC721InvalidOperator(operator){
                mstore(0,0x5b08ba18)
                mstore(0x20,operator)
                revert(0x1c,0x24)
            }
            
            function revertERC721IncorrectOwner(from, tokenId, owner){
                mstore(0,0x5b08ba18)
                mstore(0x20,from)
                mstore(0x40,tokenId)
                mstore(0x60,owner)
                revert(0x1c,0x64)
            }
            /** Utilities  */
            function _mapping(key,slot) -> s {
                mstore(0,key)
                mstore(0x20,slot)
                s := keccak256(0,0x40)
            }
            
            function selector() -> sel{
                sel := div(calldataload(0),0x100000000000000000000000000000000000000000000000000000000)
            }

            function require(condition) {
                if iszero(condition) { revert(0,0) }
            }

            function decodeAddress(offset)-> v{
                v := decodeUint(offset)
                if iszero(iszero(and(v,not(0xffffffffffffffffffffffffffffffffffffffff)))){
                    revert(0,0)
                }            
            }   

            function decodeUint(offset) -> v {
                let pos := add(4,mul(offset,0x20))
                if lt(calldatasize(),add(pos,0x20)){
                    revert(0,0)
                }

                v:=calldataload(pos)
            }
            function decodeBool(offset) -> v {
                v := decodeUint(offset)
                if gt(v,1){
                    revert(0,0)
                }
            }

            function decodeBytes(offset) -> pointer, size {
                pointer := mload(0x40)
                let pos := add(4,mul(offset,0x20))
                let lenPos := add(pos,0x20)
                let bytesLen := calldataload(lenPos)
                
                size := add(0x20, bytesLen)

                if lt(calldatasize(),add(pos,add(size,0x20))){
                     revert(0,0)
                }
                
                calldatacopy(pointer, lenPos, size)

                let module := mod(size, 0x20)
                let memPointer := add(pointer, size)
                if gt(module,0){
                    memPointer := add(memPointer, sub(0x20, module))
                }

                mstore(0x40,memPointer)
            }

            function handleStorageString(slot) -> at {
                let val := sload(slot)
                mstore(0, slot)
                let pointer := keccak256(0,0x20)
                let len := sload(pointer)
                
                at := mload(0x40)
                if iszero(len){
                    let strLen := and(val, 0xff)
                    let str := shl(8, shr(8, val))
                    mstore(at, strLen)
                    mstore(add(at, 0x20), str)
                    mstore(0x40, add(at, 0x40))
                }

                if gt(len, 0){    
                    mstore(at, len)
                    let chunks := div(len, 0x20)
                    let module := mod(len, 0x20)
                    if gt(module, 0){
                         chunks := add(chunks, 1)
                    }
                    let idx := at
                    for {let i := add(pointer, 1)} lt(i, chunks) { i := add(i, 1)}{
                        idx := add(idx, 0x20)
                        let chunk := sload(i)
                        mstore(idx, chunk)
                    } 
                    mstore(0x40, add(add(at,0x20), mul(chunks, 0x20)))
                }
                
            }
            function returnUint(v){
                mstore(0,v)
                return(0,0x20)
            }
            
            function ne(a,b) -> bool {
                bool := true
                if eq(a,b){
                    bool := false
                }
            } 

            function notZeroAddress(addr) -> b {
                b := true
                if eq(addr,0x0){
                    b := false
                }
            }

            function make0x20Compatible(val) -> b{
                let module := mod(val, 0x20)
                if gt(module, 0){
                    val := add(val, sub(0x20, module))
                }
                b := val
            }

        }
    }
}