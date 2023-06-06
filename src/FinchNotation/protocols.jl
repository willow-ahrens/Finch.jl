isprotocol(f) = false

defaultread(i) = i
isprotocol(::typeof(defaultread)) = true

walk(i) = i
isprotocol(::typeof(walk)) = true

gallop(i) = i
isprotocol(::typeof(gallop)) = true

follow(i) = i
isprotocol(::typeof(follow)) = true

defaultwrite(i) = i
isprotocol(::typeof(defaultwrite)) = true

laminate(i) = i
isprotocol(::typeof(laminate)) = true

extrude(i) = i
isprotocol(::typeof(extrude)) = true