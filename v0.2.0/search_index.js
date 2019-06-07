var documenterSearchIndex = {"docs":
[{"location":"#Introduction-1","page":"MixedSubdivisions","title":"Introduction","text":"","category":"section"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"MixedSubdivisions.jl is package for computing a (fine) mixed subdivision and the mixed volume of lattice polytopes. The mixed volume of lattice polytopes arising as Newton polytopes of a polynomial system gives an upper bound of the number of solutions of the system. This is the celebrated BKK-Theorem. A (fine) mixed subdivision can be used to efficiently solve sparse polynomial systems as first described in A Polyhedral Method for Solving Sparse Polynomial Systems by Huber and Sturmfels.","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"There are many algorithms for computing mixed volumes and mixed subdivisions. This implementation is based on the tropical homotopy continuation algorithm by Anders Jensen described in arXiv:1601.02818.","category":"page"},{"location":"#Installation-1","page":"MixedSubdivisions","title":"Installation","text":"","category":"section"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"The package can be installed via the Julia package manager","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"pkg> add MixedSubdivisions","category":"page"},{"location":"#Short-introduction-1","page":"MixedSubdivisions","title":"Short introduction","text":"","category":"section"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"We support polynomial input through the DynamicPolynomials package.","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"@polyvar x y;\n# create two polynomials\nf = y^2 + x * y + x + 1;\ng = x^2 + x * y + y + 1;\n\n# mixed volume\nmixed_volume([f, g])","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"4","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"Alternatively we could also give directly the supports to mixed_volume.","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"A = support([f, g])","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"2-element Array{Array{Int32,2},1}:\n [1 0 1 0; 1 2 0 0]\n [2 1 0 0; 0 1 1 0]","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"mixed_volume(A)","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"4","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"Now let's compute the mixed cells with respect to a given lift.","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"w₁ = [2, 0, 0, 0];\nw₂ = [8, 4, 3, 0];\nmixed_cells(A, [w₁, w₂])","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"2-element Array{MixedCell,1}:\n MixedCell:\n • volume → 3\n • indices → Tuple{Int64,Int64}[(2, 3), (4, 2)]\n • normal → [-2.66667, -1.33333]\n MixedCell:\n • volume → 1\n • indices → Tuple{Int64,Int64}[(3, 1), (1, 2)]\n • normal → [-6.0, -2.0]","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"Now let's compare that to another lift.","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"v₁ = [1, 0, 0, 0];\nv₂ = [8, 4, 3, 0];\nmixed_cells(A, [v₁, v₂])","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"3-element Array{MixedCell,1}:\n MixedCell:\n • volume → 2\n • indices → Tuple{Int64,Int64}[(2, 1), (4, 2)]\n • normal → [-2.5, -1.5]\n MixedCell:\n • volume → 1\n • indices → Tuple{Int64,Int64}[(3, 1), (2, 4)]\n • normal → [-3.0, -1.0]\n MixedCell:\n • volume → 1\n • indices → Tuple{Int64,Int64}[(3, 1), (1, 2)]\n • normal → [-5.0, -1.0]","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"If you don't want to wait until all mixed cells got computed you can also use the MixedCellIterator","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"for cell in MixedCellIterator(A, [v₁, v₂])\n    println(cell)\nend","category":"page"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"MixedCell:\n • volume → 2\n • indices → Tuple{Int64,Int64}[(2, 1), (4, 2)]\n • normal → [-2.5, -1.5]\nMixedCell:\n • volume → 1\n • indices → Tuple{Int64,Int64}[(3, 1), (2, 4)]\n • normal → [-3.0, -1.0]\nMixedCell:\n • volume → 1\n • indices → Tuple{Int64,Int64}[(3, 1), (1, 2)]\n • normal → [-5.0, -1.0]","category":"page"},{"location":"#API-1","page":"MixedSubdivisions","title":"API","text":"","category":"section"},{"location":"#","page":"MixedSubdivisions","title":"MixedSubdivisions","text":"mixed_volume\nMixedCell\nvolume\nnormal\nindices\nMixedCellIterator\nmixed_cells\nsupport","category":"page"},{"location":"#MixedSubdivisions.mixed_volume","page":"MixedSubdivisions","title":"MixedSubdivisions.mixed_volume","text":"mixed_volume(F::Vector{<:MP.AbstractPolynomialLike}; show_progress=true, algorithm=:regeneration)\nmixed_volume(𝑨::Vector{<:Matrix}; show_progress=true, algorithm=:regeneration)\n\nCompute the mixed volume of the given polynomial system F resp. represented by the support 𝑨. There are two possible values for algorithm:\n\n:total_degree: Use the total degree homotopy algorithm described in Section 7.1\n:regeneration: Use the tropical regeneration algorithm described in Section 7.2\n\n\n\n\n\n","category":"function"},{"location":"#MixedSubdivisions.MixedCell","page":"MixedSubdivisions","title":"MixedSubdivisions.MixedCell","text":"MixedCell\n\nData structure representing a (fine) mixed cell.\n\nFields\n\nindices::Vector{NTuple{2, Int}}: The columns of the support creating the mixed cell.\nnormal::Vector{Float64}: The inner normal vector of the lifted mixed cell.\nβ::Vector{Float64}: The vector (min_a in A_i aγ)_i where γ is normal.\nvolume::Int: The volume of the mixed cell.\n\n\n\n\n\n","category":"type"},{"location":"#MixedSubdivisions.volume","page":"MixedSubdivisions","title":"MixedSubdivisions.volume","text":"volume(C::MixedCell)\n\nReturns the volume of the mixed cell C.\n\n\n\n\n\n","category":"function"},{"location":"#MixedSubdivisions.normal","page":"MixedSubdivisions","title":"MixedSubdivisions.normal","text":"normal(C::MixedCell)\n\nThe inner normal vector of the lifted mixed cell.\n\n\n\n\n\n","category":"function"},{"location":"#MixedSubdivisions.indices","page":"MixedSubdivisions","title":"MixedSubdivisions.indices","text":"indices(C::MixedCell)\n\nReturns the indices of the support creating the mixed cell.\n\n\n\n\n\n","category":"function"},{"location":"#MixedSubdivisions.MixedCellIterator","page":"MixedSubdivisions","title":"MixedSubdivisions.MixedCellIterator","text":"MixedCellIterator(support:Vector{<:Matrix}, lifting::Vector{<:Vector{<:Integer}})\n\nReturns an iterator over all (fine) mixed cells of the given \u001dsupport\u001d induced by the given \u001dlifting\u001d. If the lifting is not sufficiently generic the mixed cells induced by a sligtly perturbated lifting are computed. The iterator returns in each iteration a MixedCell. Note that due to efficiency reason the same object is returned in each iteration, i.e., if you want to store the computed cells you need to make a copy. Alternatively you can also use mixed_cells to compute all mixed cells.\n\n\n\n\n\n","category":"type"},{"location":"#MixedSubdivisions.mixed_cells","page":"MixedSubdivisions","title":"MixedSubdivisions.mixed_cells","text":"mixed_cells(support::Vector{<:Matrix}, lifting::Vector{<:Vector})\n\nCompute all (fine) mixed cells of the given \u001dsupport\u001d induced by the given \u001dlifting\u001d. If the lifting is not sufficiently generic the mixed cells induced by a sligtly perturbated lifting are computed. The mixed cells are stored as a MixedCell.\n\n\n\n\n\n","category":"function"},{"location":"#MixedSubdivisions.support","page":"MixedSubdivisions","title":"MixedSubdivisions.support","text":"support(F::Vector{<:MP.AbstractPolynomialLike}, vars=MP.variables(F), T::Type{<:Integer}=Int32)\n\nCompute the support of the polynomial system F with the given variables vars. The returned matrices have element type T.\n\n\n\n\n\n","category":"function"}]
}
