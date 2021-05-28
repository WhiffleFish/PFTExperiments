using JLD2

"""
Hyperopt macro stores objective as anonymous function, which breaks save with JLD2
-> Restored version builds everything but field :objective
-> :objective filed inconsequential when looking at data so replace with x->0
"""
function RestoreHopt(path)
    d = JLD2.load(path)
    ho = first(values(d))
    h = Hyperoptimizer([getfield(ho,f) for f in fieldnames(typeof(ho))]..., x->0)
    return h
end
