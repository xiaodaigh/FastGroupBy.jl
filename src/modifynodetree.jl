type BoskoTreeNode
    parent::Int
    lchild::
end
type BoskoTree
    nodes::Vector{TreeNode}
end
BoskoTree() = Tree([TreeNode(0, Vector{Int}())])
function addchild(tree::Tree, id::Int)
    1 <= id <= length(tree.nodes) || throw(BoundsError(tree, id))
    push!(tree.nodes, TreeNode(id, Vector{}()))
    child = length(tree.nodes)
    push!(tree.nodes[id].children, child)
    child
end
children(tree, id) = tree.nodes[id].children
parent(tree,id) = tree.nodes[id].parent
