struct PhyloTree
    node::Taxon
    children::Vector{PhyloTree}
end

AbstractTrees.children(ptree::PhyloTree) = ptree.children
AbstractTrees.nodetype(::PhyloTree) = PhyloTree
AbstractTrees.printnode(io::IO, ptree::PhyloTree) = print(io, "$(ptree.node)")
Base.show(io::IO,ptree::PhyloTree) = print_tree(io, ptree)

function topolgoy(taxa::Vector{Taxon})
    root = lca(taxa)
    lineages = map(x -> lineage(x), taxa)
    all_taxon = union(lineages...)
    branches = Dict{Taxon, Taxon}()
    for node in all_taxon
        parent_node = parent(node)
        if parent_node !== nothing
            branches[node] = parent_node
        end
    end

    function _Phylotree(root::Taxon,branches::Dict{Taxon,Taxon})
        children = map(x -> _Phylotree(x,branches),findall(isequal(root),branches))
        return PhyloTree(root, children)
    end

    return _Phylotree(root, branches)
end