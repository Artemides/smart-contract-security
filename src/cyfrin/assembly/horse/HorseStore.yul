object "HorseStore"{
    code {
        //deployment code
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
        code {
            if gt(callvalue(),0){
                revert(0,0)
            }
    
            switch selector()
            case 0xcdfead2e /*updateHorseNumber(uint256) */ { 
                updateHorseNumber(decodeAsUint(0))
            }
            //read
            case 0xe026c017 /**readNumberOfHorses()*/ { 
                readNumberOfHorses()
            }
            default {
                revert(0,0)
            }
    
            function updateHorseNumber(horseNumber){
                sstore(horseNumberSlot(), horseNumber)
            }
    
            function readNumberOfHorses(){
                let horseNumber := sload(horseNumberSlot())
                mstore(0, horseNumber)
                return(0, 0x20)
            }
    
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }
    
            
            function decodeAsUint(offset) -> v {
                let pos := add(4,mul(offset,0x20))

                if lt(calldatasize(),add(pos,0x20)){
                    revert(0,0)
                }

                v := calldataload(pos)
            }
            
            function horseNumberSlot() -> slot{
                slot := 0
            }
        }
    }

    
    
}