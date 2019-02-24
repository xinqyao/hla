if(basename(getwd()) != 'production')
{
    stop('`Rscript split_mdout.r` to be run from `production` dir ...')
}
mbar_lambdas <- seq(0, 1, 0.05)
mdout_file <- 'prod.out'
dir_data <- 'data'
if(!dir.exists(dir_data))
{
    # stop('Data dir: ', dir_data, ' not found. Quitting.')
    dir.create(dir_data)
}

mdout_raw <- readLines(mdout_file)#, n=500)
ind_results <- grep('   4.  RESULTS', mdout_raw)
ind_timings <- grep('   5.  TIMINGS', mdout_raw)
ind_mbar_first <- grep('^MBAR[[:blank:]]Energy[[:blank:]]analysis', mdout_raw)[1]
ind_lambda_change <- grep('^Dynamically[[:blank:]]changing[[:blank:]]lambda', mdout_raw)
# start one line before MBAR Energy analysis print
ind_lambda_start <- ind_lambda_change + 2
ind_lambda_start <- ind_lambda_start[-length(ind_lambda_start)]
ind_lambda_start <- c(ind_mbar_first-1, ind_lambda_start)
# end three lines before next change, look for '|======' line
ind_lambda_end <- ind_lambda_change - 3
rm(ind_lambda_change)
windows <- data.frame(start=ind_lambda_start, end=ind_lambda_end)

out_header <- mdout_raw[seq_len(ind_results-2)]
ind_header_clambda <- grep('clambda.*=', out_header)
insert_header <- sapply(out_header[ind_header_clambda], function(x)
       {
           gsub('clambda.*=.*,', 'clambda = XXXX,', x)
       })
out_header[ind_header_clambda] <- as.character(insert_header)
out_header_results <- mdout_raw[seq(ind_results-1, ind_results+1)]
out_footer <- mdout_raw[seq(ind_timings-2, length(mdout_raw))]

out <- lapply(seq_len(nrow(windows)), function(i)
             {
                 window <- as.numeric(windows[i,])
                 new_header <- gsub('XXXX', sprintf('%.4f', mbar_lambdas[i]), out_header)
                 return(c(new_header, out_header_results,
                   mdout_raw[seq(window[1], window[2])],
                   out_footer))
             })
if(length(mbar_lambdas) != length(out))
{
    stop('Number of output files do not match number of lambdas')
}
for(i in seq_along(mbar_lambdas))
{
    window <- sprintf('%.2f', mbar_lambdas[i])
    dir.create(file.path(dir_data, window))
    window <- paste0(dir_data, '/', window, '/prod_',
                     gsub('[.]', '', window), '.out')
    write(out[[i]], file=window)
}

rm(mdout_raw, out); gc()

