################################################################################
#' Merge arguments into one phyloseq object.
#'
#' Takes a comma-separated list of phyloseq objects as arguments,
#' and returns the most-comprehensive single phyloseq object possible.
#'
#' Higher-order objects can be created if arguments are appropriate component data
#' types of different
#' classes, and this should mirror the behavior of the \code{\link{phyloseq}} method,
#' which is the suggested method if the goal is simply to create a higher-order
#' phyloseq object from different data types (1 of each class) describing the same experiment.
#'
#' By contrast, this method is intended for situations in which one wants to combine
#' multiple higher-order objects, or multiple core component data objects (e.g. more than one
#' \code{otu_table}) that should be combined into one object.
#'
#' Merges are performed by first separating higher-order objects into
#' a list of their component objects; then, merging any component objects of the same class
#' into one object according to the behavior desribed in \code{\link{modmerge_phyloseq_pair}};
#' and finally, building back up a merged-object according to the constructor
#' behavior of the \code{\link{phyloseq}} method. If the arguments contain only a single
#' component type -- several otu_table objects, for example -- then a single merged object
#' of that component type is returned.
#'
#' @usage modmerge_phyloseq(...)
#'
#' @param ... a comma-separated list of phyloseq objects.
#'
#' @return Merges are performed by first separating higher-order objects into
#' a list of their component objects; then, merging any component objects of the same class
#' into one object according to the behavior desribed in \code{\link{modmerge_phyloseq_pair}};
#' and finally, re-building a merged-object according to the constructor
#' behavior of the \code{\link{phyloseq}} method. If the arguments contain only a single
#' component type -- several otu_table objects, for example -- then a single merged object
#' of the relevant component type is returned.
#'
#' Merges between 2 or more tree objects are ultimately done using
#' \code{\link[ape]{consensus}} from the ape package.
#' This has the potential to limit somewhat the final data object, because trees
#' don't merge with other trees in the same granular manner as data tables, and
#' ultimately the species/taxa in higher-order phyloseq objects will be clipped to
#' what is contained in the tree. If this an issue, the tree component should
#' be ommitted from the argument list.
#'
#' @export
#'
#' @examples #
#' ## # Make a random complex object
#' ## OTU1 <- otu_table(matrix(sample(0:5,250,TRUE),25,10), taxa_are_rows=TRUE)
#' ## tax1 <- tax_table(matrix("abc", 30, 8))
#' ## map1 <- data.frame( matrix(sample(0:3,250,TRUE),25,10),
#' ##   matrix(sample(c("a","b","c"),150,TRUE), 25, 6) )
#' ## map1 <- sample_data(map1)
#' ## exam1 <- phyloseq(OTU1, map1, tax1)
#' ## x <- exam1
#' ## x <- phyloseq(exam1)
#' ## y <- tax_table(exam1)
#' ## modmerge_phyloseq(x, y)
#' ## modmerge_phyloseq(y, y, y, y)
modmerge_phyloseq <- function(...){
	arguments <- list(...)
	# create list of all components of all objects
	comp.list <- list()
	for( i in 1:length(arguments) ){
		comp.list <- c(comp.list, splat.phyloseq.objects(arguments[[i]]))
	}
	# loop through each component type. Note, list names redundant. will use this
	merged.list <- list()
	for( i in unique(names(comp.list)) ){ #i="tax_table"
		# check if length 1, if so, cat to merged.list.
		i.list <- comp.list[names(comp.list)==i]
		if( length(i.list) == 1 ){
			merged.list <- c(merged.list, i.list)
		} else {
			# else, loop through each identically-named objects.
			x1 <- i.list[[1]]
			for( j in 2:length(i.list)){
				x1 <- modmerge_phyloseq_pair(x1, i.list[[j]])
			}
			x1 <- list(x1)
			names(x1)   <- i
			merged.list <- c(merged.list, x1)
		}
	}
	# Remove names to avoid any conflicts with phyloseq(), which does not need named-arguments
	names(merged.list) <- NULL

	# Use do.call for calling this variable-length, variable-content argument list.
	return( do.call(phyloseq, merged.list) )
}
################################################################################
#' Merge pair of phyloseq component data objects of the same class.
#'
#' Internal S4 methods to combine pairs of objects of classes specified in the
#' phyloseq package. These objects must be component data of the same type
#' (class). This is mainly an internal method, provided to illustrate how
#' merging is performed by the more general \code{\link{modmerge_phyloseq}} function.
#'
#' The \code{\link{modmerge_phyloseq}} function is recommended in general.
#'
#' Special note: non-identical trees are merged using \code{\link[ape]{consensus}}.
#'
#' @usage modmerge_phyloseq_pair(x, y)
#'
#' @param x A character vector of the species in object x that you want to
#' keep -- OR alternatively -- a logical vector where the kept species are TRUE, and length
#' is equal to the number of species in object x. If \code{species} is a named
#' logical, the species retained is based on those names. Make sure they are
#' compatible with the \code{taxa_names} of the object you are modifying (\code{x}).
#'
#' @param y Any \code{phyloseq} object.
#'
#' @return A single component data object that matches \code{x} and \code{y}
#' arguments. The returned object will
#' contain the union of the species and/or samples of each. If there is redundant
#' information between a pair of arguments of the same class, the values in \code{x} are
#' used by default. Abundance values are summed for \code{otu_table} objects
#' for those elements that describe the same species and sample in \code{x}
#' and \code{y}.
#'
#' @seealso \code{\link{modmerge_phyloseq}} \code{\link{modmerge_taxa}}
#'
#' @rdname modmerge_phyloseq_pair-methods
#' @docType methods
#' @export
#'
#' @examples #
#' ## # merge two simulated otu_table objects.
#' ## x  <- otu_table(matrix(sample(0:5,200,TRUE),20,10), taxa_are_rows=TRUE)
#' ## y  <- otu_table(matrix(sample(0:5,300,TRUE),30,10), taxa_are_rows=FALSE)
#' ## xy <- modmerge_phyloseq_pair(x, y)
#' ## yx <- modmerge_phyloseq_pair(y, x)
#' ## # merge two simulated tax_table objects
#' ## x <- tax_table(matrix("abc", 20, 6))
#' ## y <- tax_table(matrix("def", 30, 8))
#' ## xy <- modmerge_phyloseq_pair(x, y)
#' ## # merge two simulated sample_data objects
#' ## x <- data.frame( matrix(sample(0:3,250,TRUE),25,10),
#' ##   matrix(sample(c("a","b","c"),150,TRUE),25,6) )
#' ## x <- sample_data(x)
#' ## y <- data.frame( matrix(sample(4:6,200,TRUE),20,10),
#' ##   matrix(sample(c("d","e","f"),120,TRUE),20,8) )
#' ## y <- sample_data(y)
#' ## modmerge_phyloseq_pair(x, y)
#' ## data.frame(modmerge_phyloseq_pair(x, y))
#' ## data.frame(modmerge_phyloseq_pair(y, x))
setGeneric("modmerge_phyloseq_pair", function(x, y) standardGeneric("modmerge_phyloseq_pair"))
################################################################################
#' @aliases modmerge_phyloseq_pair,otu_table,otu_table-method
#' @rdname modmerge_phyloseq_pair-methods
setMethod("modmerge_phyloseq_pair", signature("otu_table", "otu_table"), function(x, y){
	specRrowsx   <- taxa_are_rows(x)
	new.sp.names <- union(taxa_names(x), taxa_names(y))
	new.sa.names <- union(sample_names(x), sample_names(y))

	# Create the empty new matrix structure
	newx <- matrix(0, nrow=length(new.sp.names), ncol=length(new.sa.names),
		dimnames=list(new.sp.names, new.sa.names))

	# assign a standard taxa_are_rows orientation to TRUE for x and y
	if( !taxa_are_rows(x) ){ x <- t(x) }
	if( !taxa_are_rows(y) ){ y <- t(y) }

	# "merge" by addition.
	newx[rownames(x), colnames(x)] <- x
	newx[rownames(y), colnames(y)] <- newx[rownames(y), colnames(y)] + y

	# Create the new otu_table object
	newx <- otu_table(newx, taxa_are_rows=TRUE)

	# Return the orientation that was in x
	if( !specRrowsx ){ newx <- t(newx) }
	return(newx)
})
################################################################################
#' @aliases modmerge_phyloseq_pair,taxonomyTable,taxonomyTable-method
#' @rdname modmerge_phyloseq_pair-methods
setMethod("modmerge_phyloseq_pair", signature("taxonomyTable", "taxonomyTable"), function(x, y){
	new.sp.names <- union(rownames(x), rownames(y))
	new.ta.names <- union(colnames(x), colnames(y))

	# Create the empty new matrix structure
	newx <- matrix(NA, nrow=length(new.sp.names), ncol=length(new.ta.names),
		dimnames=list(new.sp.names, new.ta.names))

	# "merge". Overwrite with x information.
	newx[rownames(y), colnames(y)] <- y
	newx[rownames(x), colnames(x)] <- x

	# Create the new otu_table object
	newx <- tax_table(newx)

	return(newx)
})
################################################################################
#' @aliases modmerge_phyloseq_pair,sample_data,sample_data-method
#' @rdname modmerge_phyloseq_pair-methods
setMethod("modmerge_phyloseq_pair", signature("sample_data", "sample_data"), function(x, y){
	new.sa.names <- union(rownames(x), rownames(y))
	new.va.names <- union(colnames(x), colnames(y))

	partx <- data.frame("X0"=rownames(x), x)
	party <- data.frame("X0"=rownames(y), y)
	newx <- merge(partx, party, all=TRUE)
	# now we have the correct template, lets remove redundant rows.
	keep.samp.rows <- sapply(unique(as.character(newx[,1])), function(i,nx){
		rownames(subset(nx, X0==i))[1]
	},newx)
	newx <- newx[keep.samp.rows,]
	rownames(newx) <- as.character(newx$"X0")

	# "merge". Overwrite with x information.
	newx[rownames(y), colnames(y)] <- data.frame(y)
	newx[rownames(x), colnames(x)] <- data.frame(x)

	# trim the sample name column
	newx <- newx[,names(newx)!="X0"]

	# Create the new otu_table object
	newx <- sample_data(newx)
	return(newx)
})
################################################################################
#' @aliases modmerge_phyloseq_pair,phylo,phylo-method
#' @rdname modmerge_phyloseq_pair-methods
#' @importFrom ape consensus
setMethod("modmerge_phyloseq_pair", signature("phylo", "phylo"), function(x, y){
	if(identical(x, y)){
		return(x)
	} else {
		return( consensus(x, y)	)
	}
})
################################################################################
#' @aliases modmerge_phyloseq_pair,XStringSet,XStringSet-method
#' @rdname modmerge_phyloseq_pair-methods
setMethod("modmerge_phyloseq_pair", signature("XStringSet", "XStringSet"), function(x, y){
	if( class(x) != class(y) ){
		# if class of x and y don't match, throw warning, try anyway (just in case)
		warning("For merging reference sequence objects, x and y should be same type.\n",
			"That is, the same subclass of XStringSet. e.g. both DNAStringSet.\n",
			"Try coercing each to the same compatible class prior to merge.")
	}
	# Add to x the stuff that is in y, but not in x
	add_y_taxa = setdiff(taxa_names(y), taxa_names(x))
	if( length(add_y_taxa) < 1L ){
		# If there is nothing from y to add, just return x as-is
		return(x)
	} else {
		# Else, add unique stuff from y only to x (they are both lists!)
		x = c(x, y[add_y_taxa])
		return(x)
	}
})
################################################################################
################################################################################
#' Merge a subset of the species in \code{x} into one species/taxa/OTU.
#'
#' Takes as input an object that describes species/taxa
#' (e.g. \code{\link{phyloseq-class}}, \code{\link{otu_table-class}},
#'  \code{\link{phylo-class}}, \code{\link{taxonomyTable-class}}),
#' as well as
#' a vector of species that should be merged.
#' It is intended to be able to operate at a low-level such that
#' related methods, such as \code{\link{tip_glom}} and \code{\link{tax_glom}}
#' can both reliably call \code{modmerge_taxa} for their respective purposes.
#'
#' @usage modmerge_taxa(x, eqtaxa, archetype=1)
#'
#' @param x (Required). An object that describes species (taxa). This includes
#'  \code{\link{phyloseq-class}}, \code{\link{otu_table-class}}, \code{\link{taxonomyTable-class}},
#'  \code{\link[ape]{phylo}}.
#'
#' @param eqtaxa (Required). The species names, or indices, that should be merged together.
#'  If \code{length(eqtaxa) < 2}, then the object \code{x} will be returned
#'  safely unchanged.
#'
#' @param archetype (Optional). A single-length numeric or character.
#'  The index of \code{eqtaxa}, or OTU ID,
#'  indicating the species that should be kept to represent
#'  the summed/merged group of species/taxa/OTUs.
#'  The default is to use the OTU with the largest count total
#'  if counts are available, or to use \code{1}
#'  (the first OTU in \code{eqtaxa}) otherwise.
#'  If \code{archetype} is not a valid index or index-name in \code{eqtaxa},
#'  the first will be used, and the value in archetype will be used
#'  as the index-name for the new species.
#'
#' @return The object, \code{x}, in its original class, but with the specified
#'   species merged into one entry in all relevant components.
#'
#' @seealso \code{\link{tip_glom}}, \code{\link{tax_glom}}, \code{\link{modmerge_phyloseq}},
#'  \code{\link{modmerge_samples}}
#'
#' @export
#' @docType methods
#' @rdname modmerge_taxa-methods
#' @examples #
#' data(esophagus)
#' tree <- phy_tree(esophagus)
#' otu  <- otu_table(esophagus)
#' otutree0 <- phyloseq(otu, tree)
#' # plot_tree(otutree0)
#' otutree1 <- modmerge_taxa(otutree0, 1:8, 2)
#' # plot_tree(esophagus, ladderize="left")
setGeneric("modmerge_taxa", function(x, eqtaxa, archetype=1L) standardGeneric("modmerge_taxa"))
################################################################################
#' @keywords internal
modmerge_taxa.indices.internal = function(x, eqtaxa, archetype){
	## If eqtaxa or archetype are character, interpret them to be OTUs and coerce them to integer indices
	if( is.character(archetype) ){
		# If archetype is already an OTU, just assign it to keepIndex
		keepIndex = which(taxa_names(x) %in% archetype[1L])
	} else {
		# Else archetype is the numeric index of the eqtaxa that should be kept.
		# Need to grab from unmodifed eqtaxa, and then decide
		archetype = eqtaxa[as.integer(archetype[1L])]
		if( is.character(archetype) ){
			# If archetype is now an OTU name, find the index and assign to keepIndex
			keepIndex = which(taxa_names(x) == archetype[1L])
		} else {
			# Otherwise, assume it is a taxa index, and assign to keepIndex
			keepIndex = as.integer(archetype)
		}
	}
	# Ensure eqtaxa is the integer indices of the taxa that are being merged together
	if( is.character(eqtaxa) ){
		# assume OTU name, index it against the OTU names in x
		eqtaxa = which(taxa_names(x) %in% eqtaxa)
	} else {
		# Else assume numeric index of the OTU that are being merged
		eqtaxa = as.integer(eqtaxa)
	}
	# keepIndex is index of the OTU that is kept / everything merged into.
	# It must be among the set of indices in eqtaxa or there is a logic error. Stop.
	if( length(keepIndex) <= 0L ){ stop("invalid archetype provided.") }
	if( !keepIndex %in% eqtaxa ){ stop("invalid archetype provided. It is not part of eqtaxa.") }
	# removeIndex is the index of each OTU that will be removed
	removeIndex = setdiff(eqtaxa, keepIndex)
	# Check that indices are valid
	allIndices = unlist(list(keepIndex, removeIndex))
	if( any(allIndices > ntaxa(x) | allIndices < 0L) ){
		stop("invalid OTU indices provided as eqtaxa or archetype.")
	}
	return(list(removeIndex=removeIndex, keepIndex=keepIndex))
}
################################################################################
#' @aliases modmerge_taxa,phyloseq-method
#' @rdname modmerge_taxa-methods
setMethod("modmerge_taxa", "phyloseq", function(x, eqtaxa,
    archetype=eqtaxa[which.max(taxa_sums(x)[eqtaxa])]){

	comp_list   <- splat.phyloseq.objects(x)
	merged_list <- lapply(comp_list, modmerge_taxa, eqtaxa, archetype)
	# the element names can wreak havoc on do.call
	names(merged_list) <- NULL
	# Re-instantiate the combined object using the species-merged object.
	do.call("phyloseq", merged_list)
})
###############################################################################
# Don't need to merge anything for sample_data. Return As-is.
#' @aliases modmerge_taxa,sample_data-method
#' @rdname modmerge_taxa-methods
setMethod("modmerge_taxa", "sample_data", function(x, eqtaxa, archetype=1L){
	return(x)
})
###############################################################################
#' @aliases modmerge_taxa,otu_table-method
#' @rdname modmerge_taxa-methods
setMethod("modmerge_taxa", "otu_table", function(x, eqtaxa,
    archetype=eqtaxa[which.max(taxa_sums(x)[eqtaxa])]){

	if( length(eqtaxa) < 2 ){
		return(x)
	}
	indList = modmerge_taxa.indices.internal(x, eqtaxa, archetype)
	removeIndex = indList$removeIndex
	keepIndex   = indList$keepIndex
	# Merge taxa by summing all the equivalent taxa and assigning to the one in keepIndex
	if( taxa_are_rows(x) ){
		x[keepIndex, ] = colSums(x[eqtaxa, ])
	} else {
		x[, keepIndex] = rowSums(x[, eqtaxa])
	}
	# For speed, use matrix subsetting instead of prune_taxa()
	if (taxa_are_rows(x)) {
		x = x[-removeIndex, , drop = FALSE]
	} else {
		x = x[, -removeIndex, drop = FALSE]
	}
	return(x)
})
###############################################################################
#' @importFrom ape drop.tip
#' @aliases modmerge_taxa,phylo-method
#' @rdname modmerge_taxa-methods
setMethod("modmerge_taxa", "phylo", function(x, eqtaxa, archetype=1L){
	# If there is nothing to merge, return x as-is
	if( length(eqtaxa) < 2 ){
		return(x)
	}
	indList = modmerge_taxa.indices.internal(x, eqtaxa, archetype)
	removeIndex = indList$removeIndex
	# If there is too much to merge (tree would have 1 or 0 branches), return NULL/warning
	if( length(removeIndex) >= (ntaxa(x)-1) ){
		# Can't have a tree with 1 or fewer tips
		warning("modmerge_taxa attempted to reduce tree to 1 or fewer tips.\n tree replaced with NULL.")
		return(NULL)
	# Else, drop the removeIndex tips and returns the pruned tree.
	} else {
		return( drop.tip(x, removeIndex) )
	}
})
###############################################################################
#' @importClassesFrom Biostrings XStringSet
#' @aliases modmerge_taxa,XStringSet-method
#' @rdname modmerge_taxa-methods
setMethod("modmerge_taxa", "XStringSet", function(x, eqtaxa, archetype=1L){
	# If there is nothing to merge, return x as-is
	if( length(eqtaxa) < 2 ){
		return(x)
	}
	indList = modmerge_taxa.indices.internal(x, eqtaxa, archetype)
	removeIndex = indList$removeIndex
	# If there is too much to merge (refseq would have 0 sequences), return NULL/warning
	if( length(removeIndex) >= ntaxa(x) ){
		# Can't have a refseq list with less
		warning("modmerge_taxa attempted to reduce reference sequence list to 0 sequences.\n refseq replaced with NULL.")
		return(NULL)
	} else {
		# Else, drop the removeIndex sequences and returns the pruned XStringSet object
		x <- x[-removeIndex]
		return(x)
	}
})
################################################################################
#' @aliases modmerge_taxa,taxonomyTable-method
#' @rdname modmerge_taxa-methods
setMethod("modmerge_taxa", "taxonomyTable", function(x, eqtaxa, archetype=1L){
	if( length(eqtaxa) < 2 ){
		return(x)
	}
	indList = modmerge_taxa.indices.internal(x, eqtaxa, archetype)
	removeIndex = indList$removeIndex
	keepIndex   = indList$keepIndex
	# # # Taxonomy is trivial in ranks after disagreement among merged taxa
	# # # Make those values NA_character_
	taxmerge  <- as(x, "matrix")[eqtaxa, ]
	bad_ranks <- apply(taxmerge, 2, function(i){ length(unique(i)) != 1 })
	# Test if all taxonomies agree. If so, do nothing. Just continue to pruning.
	if( any(bad_ranks) ){
		# The col indices of the bad ranks
		bad_ranks <- min(which(bad_ranks)):length(bad_ranks)
		# Replace bad taxonomy elements in the archetype only (others are pruned)
		x[keepIndex, bad_ranks] <- NA_character_
	}
	# Finally, remove the OTUs that have been merged into keepIndex
	return( x[-removeIndex, , drop = FALSE] )
})
################################################################################
################################################################################
#' Merge samples based on a sample variable or factor.
#'
#' The purpose of this method is to merge/agglomerate the sample indices of a
#' phyloseq object according to a categorical variable contained in a sample_data
#' or a provided factor.
#'
#' NOTE: (\code{\link[ape]{phylo}}) trees and \code{\link{taxonomyTable-class}}
#' are not modified by this function, but returned in the output object as-is.
#'
#' @usage modmerge_samples(x, group, fun=mean)
#'
#' @param x (Required). An instance of a phyloseq class that has sample indices. This includes
#'  \code{\link{sample_data-class}}, \code{\link{otu_table-class}}, and \code{\link{phyloseq-class}}.
#'
#' @param group (Required). Either the a single character string matching a variable name in
#'  the corresponding sample_data of \code{x}, or a factor with the same length as
#'  the number of samples in \code{x}.
#'
#' @param fun (Optional). The function that will be used to merge the values that
#'  correspond to the same group for each variable. It must take a numeric vector
#'  as first argument and return a single value. Default is \code{\link[base]{mean}}.
#'  Note that this is (currently) ignored for the otu_table, where the equivalent
#'  function is \code{\link[base]{sum}}, but evaluated via \code{\link[base]{rowsum}}
#'  for efficiency.
#'
#' @return A phyloseq object that has had its sample indices merged according to
#'  the factor indicated by the \code{group} argument. The output class
#'  matches \code{x}.
#'
#' @seealso \code{\link{modmerge_taxa}}, code{\link{modmerge_phyloseq}}
#'
#' @rdname modmerge_samples-methods
#' @docType methods
#' @export
#'
#' @examples #
#' data(GlobalPatterns)
#' GP = GlobalPatterns
#' mergedGP = modmerge_samples(GlobalPatterns, "SampleType")
#' SD = modmerge_samples(sample_data(GlobalPatterns), "SampleType")
#' print(SD)
#' print(mergedGP)
#' sample_names(GlobalPatterns)
#' sample_names(mergedGP)
#' identical(SD, sample_data(mergedGP))
#' # The OTU abundances of merged samples are summed
#' # Let's investigate this ourselves looking at just the top10 most abundance OTUs...
#' OTUnames10 = names(sort(taxa_sums(GP), TRUE)[1:10])
#' GP10  = prune_taxa(OTUnames10,  GP)
#' mGP10 = prune_taxa(OTUnames10, mergedGP)
#' ocean_samples = sample_names(subset(sample_data(GP), SampleType=="Ocean"))
#' print(ocean_samples)
#' otu_table(GP10)[, ocean_samples]
#' rowSums(otu_table(GP10)[, ocean_samples])
#' otu_table(mGP10)["Ocean", ]
setGeneric("modmerge_samples", function(x, group, fun=mean) standardGeneric("modmerge_samples"))
################################################################################
#' @aliases modmerge_samples,sample_data-method
#' @rdname modmerge_samples-methods
setMethod("modmerge_samples", signature("sample_data"), function(x, group, fun=mean){
	x1    <- data.frame(x)

	# Check class of group and modify if "character"
	if( class(group)=="character" & length(group)==1 ){
		if( !group %in% colnames(x) ){stop("group not found among sample variable names.")}
		group <- x1[, group]
	}
	if( class(group)!="factor" ){
		# attempt to coerce to factor
		group <- factor(group)
	}

	# # Remove any non-coercable columns.
	# # Philosophy is to keep as much as possible. If it is coercable at all, keep.
	# # Coerce all columns to numeric matrix
	# coercable    <- sapply(x1, canCoerce, "numeric")
	# x2           <- sapply(x1[, coercable], as, "numeric")
	# rownames(x2) <- rownames(x1)

	# Perform the aggregation.
	outdf <- aggregate(x1, list(group), fun)
	# get rownames from the "group" column (always first)
	# rownames(outdf) <- as.character(outdf[, 1])
	rownames(outdf) <- levels(group)
	# "pop" the first column
	outdf <- outdf[, -1, drop=FALSE]

	return( sample_data(outdf) )
})
################################################################################
#' @aliases modmerge_samples,otu_table-method
#' @rdname modmerge_samples-methods
setMethod("modmerge_samples", signature("otu_table"), function(x, group){
	# needs to be in sample-by-species orientation
	if( taxa_are_rows(x) ){ x <- t(x) }
	# coerce to matrix, x2
	x2 <- as(x, "matrix")

	# # # #aggregate(x2, list(group), fun)
	out <- rowsum(x2, group)

	# convert back to otu_table, and return
	return( otu_table(out, taxa_are_rows=FALSE) )
})
################################################################################
#' @aliases modmerge_samples,phyloseq-method
#' @rdname modmerge_samples-methods
setMethod("modmerge_samples", signature("phyloseq"), function(x, group, fun=mean){

	# Check if phyloseq object has a sample_data
	if( !is.null(sample_data(x, FALSE)) ){
		# Check class of group and modify if single "character" (column name)
		if( class(group)=="character" & length(group)==1 ){
			x1 <- data.frame(sample_data(x))
			if( !group %in% colnames(x1) ){stop("group not found among sample variable names.")}
			group <- x1[, group]
		}
		# coerce to factor
		if( class(group)!="factor" ){ group <- factor(group) }
		# Perform merges.
		newSM <- modmerge_samples(sample_data(x), group, fun)
		newOT <- modmerge_samples(otu_table(x), group)
		phyloseqList <- list(newOT, newSM)
	# Else, the only relevant object to "modmerge_samples" is the otu_table
	} else {
		if( class(group)!="factor" ){ group <- factor(group) }
		phyloseqList <- list( newOT=modmerge_samples(otu_table(x), group) )
	}

	### Add to build-call-list the remaining components, if present in x.
	### NULL is returned by accessor if object lacks requested component/slot.
	### Order of objects in list doesn't matter for phyloseq.
	### The list should not be named.
	if( !is.null(access(x, "tax_table")) ){ phyloseqList <- c(phyloseqList, list(tax_table(x))) }
	if( !is.null(access(x, "phy_tree"))    ){ phyloseqList <- c(phyloseqList, list(phy_tree(x))) }

	return( do.call("phyloseq", phyloseqList) )
})
################################################################################
