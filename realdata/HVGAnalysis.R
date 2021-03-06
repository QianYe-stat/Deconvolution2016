# Analysing ranking of HVG's
source("./functions.R")
require(scran)

out.dir <- "./HVGresults"
dir.create(out.dir)

for (x in c("Zeisel","Klein")) {
    cur.data <- readRDS(sprintf("%sData.rds", x))
    counts <- cur.data$Counts
    size.facs <- cur.data$SF
    ranking <- list()
    top.ranked <- list()

    for (y in colnames(size.facs)) {
        norm.counts <- as.data.frame(t(t(counts) / size.facs[,y]))
        features <- featureCalc(norm.counts, htseq=FALSE, 1)
        dm <- DM(features$mean, features$cv2)
        ranking[[y]] <- rank(-dm, ties.method="first")
        top.ranked[[y]] <- rownames(features)[order(dm, decreasing=TRUE)]
    }
    top.ranked <- data.frame(top.ranked)
    
    out.file <- sprintf("%s_HVG_ranking.txt", x)
    isfirst <- TRUE
    comp <- function(a, b, top) { sprintf("%.2f", sum(a<=top & b<=top)/top) }
    for (top in c(100, 500, 2000)) {
        write.table(data.frame(Top=top, 
                              SF=comp(ranking$DESeq, ranking$Deconvolution, top), 
                              TMM=comp(ranking$TMM, ranking$Deconvolution, top), 
                              Lib=comp(ranking$LibSize, ranking$Deconvolution, top)),
                    append=!isfirst, col.names=isfirst, row.names=FALSE, quote=FALSE, sep="\t",
                    file=file.path(out.dir, out.file))
        isfirst <- FALSE
        
        comparisonMatrix <- compareHVG(top.ranked, top)
        write.table(comparisonMatrix, file.path(out.dir, paste0(x, "HVGTop", top, ".txt")))
    }
}

