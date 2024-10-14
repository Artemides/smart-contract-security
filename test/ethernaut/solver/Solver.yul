object "Solver"{
    code {
        datacopy(0, dataoffset("runtime"),datasize("runtime"))
        return(0, datasize("runtime"))
    }
    
    object "runtime"{
      code{
        let selector := div(calldataload(0),0x100000000000000000000000000000000000000000000000000000000)
        if eq(0x650500c1,selector) {
            mstore(0,0x2a)
            return(0,0x20)
        }
      }
    }
}