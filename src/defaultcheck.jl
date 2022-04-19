"""
    hasdefaultcheck(lvl)

Can the level check whether it is entirely default?
"""
hasdefaultcheck(lvl) = false

"""
    getdefaultcheck(env)

Return a variable which should be set to false if the subfiber is not entirely default.
"""
getdefaultcheck(lvl) = nothing

"""
    envdefaultcheck(env)

Return a variable which should be set to false if the subfiber is not entirely default.
"""
envdefaultcheck(env) = get(env, :guard, nothing)