struct PhyloTree
    node::Taxon
    children::Vector{PhyloTree}
end

AbstractTrees.children(ptree::PhyloTree) = ptree.children
AbstractTrees.nodetype(::PhyloTree) = PhyloTree
AbstractTrees.printnode(io::IO, ptree::PhyloTree) = print(io, "$(ptree.node)")
Base.show(io::IO,ptree::PhyloTree) = print_tree(io, ptree)

function topolgoy(taxa::Vector{Taxon}; intermediate=false)
    root = lca(taxa)
    lineages = map(Lineage, taxa)
    all_taxon = union(lineages...)
    branches = Dict{Taxon, Taxon}()
    for node in all_taxon
        parent_node = parent(node)
        if parent_node !== nothing
            branches[node] = parent_node
        end
    end
    return _Phylotree(root, branches; intermediate=intermediate)
end

function _Phylotree(root::Taxon,branches::Dict{Taxon,Taxon}; intermediate=false)
    children_node = findall(isequal(root),branches)
    if (!intermediate) &&  (length(children_node) == 1)
        root = children_node[1]
        return _Phylotree(root, branches; intermediate=intermediate)
    end
    children = map(x -> _Phylotree(x,branches;intermediate=intermediate),children_node)
    return PhyloTree(root, children)
end