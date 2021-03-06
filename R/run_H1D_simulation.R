#' This is the main simulation function
#'
#' @param project.path
#' @param hydrus.path
#' @param profile.depth
#' @param beginT
#' @param endT  end time
#' @param deltaT time step
#' @param bot.bc.type head or flux type
#' @param bot.bc.value  value of the bc
#' @param const.bot.bc Logical, to set if bottom BC is constant
#' @param soil.para Hydraulic parameters of soil (van Genuchten)
#' @param atm.bc.data data frame containing atmonspheric boundary conditions (time variable BC)
#' @param ini.wt Initial water table depth
#' @param rdepth rooting depth
#' @param obs.nodes Observation node points (vector)
#' @param show.output Logical, whether the shell output of HYDRUS1D run should be displayed on R console, default = F
#'
#' @export
#'
#' @examples

run.H1D.simulation = function(project.path, hydrus.path = NULL, profile.depth,
                              beginT, endT, deltaT, bot.bc.type, bot.bc.value, const.bot.bc,
                              soil.para, atm.bc.data, ini.wt, TimeUnit = "days",
                              rdepth, obs.nodes, show.output = TRUE, ...) {

   sapply(list.files(project.path, pattern = "\\.OUT|\\.out", full.names = T), file.remove)

   error_file = file.path(project.path, "Error.msg")
   if(file.exists(error_file))  file.remove(error_file)

   if(is.null(hydrus.path)|missing(hydrus.path)){
      hydrus.path = "C:/Program Files (x86)/PC-Progress/Hydrus-1D 4.xx"
   }

   maxTp = endT/deltaT
   times_s = seq(beginT, endT, by = deltaT)

   prev_sims = dir(project.path, pattern = "sim", full.names = T)

   if(length(prev_sims > 0)){
      mapply(FUN = unlink, prev_sims, recursive = T, force = T)
   }

   if(maxTp <= 960) {

      write.atmosph.in(project.path, maxAL = maxTp, deltaT = deltaT,
                       atm.bc.data = atm.bc.data[1:maxTp, ])

      write.print.times(project.path, tmin = beginT, tmax = endT,
                        tstep = deltaT, TimeUnit = TimeUnit)

      call.H1D(project.path, hydrus.path = hydrus.path, show.output = show.output)

   } else {

      cat("Calculating times", 1, "to", 960*deltaT, ".....\n")

      write.atmosph.in(project.path, maxAL = 960, deltaT = deltaT,
                       atm.bc.data = atm_bc_data[1:960, ])

      write.print.times(project.path, tmin = beginT, tmax = 960*deltaT,
                        tstep = deltaT, TimeUnit = TimeUnit)

      call.H1D(project.path, hydrus.path = hydrus.path, show.output = show.output)

      error_test = file.exists(error_file)
      #################
      if(isTRUE(error_test)){

         error_msg = readLines(error_file, n = -1L, encoding = "unknown")
         error_msg = paste(error_msg, collapse = "")
         cat(error_msg, ".....\n")
         return(invisible(error_msg))

      } else {

         sim_number = ceiling(maxTp/960)

         sim1_files = list.files(project.path, full.names = TRUE)

         sim1_folder = file.path(project.path,"sim1")
         dir.create (sim1_folder)

         sapply(sim1_files, file.copy, to = sim1_folder)

         options(warn = -1)
         h1d_output =  data.table::fread(input = file.path(project.path, "Nod_Inf.out"),
                                         fill = TRUE, blank.lines.skip = FALSE, skip = 10)

         time_ind = grep("Time:", h1d_output[["Node"]])
         to_skip = time_ind[length(time_ind)]+2

         head_profile = h1d_output[to_skip:nrow(h1d_output), c("Node", "Depth", "Head")]
         head_profile = as.data.frame(apply(head_profile, 2, as.numeric))
         head_profile = na.omit(head_profile)
         pressure_vec = head_profile$Head

         options(warn = 0)

         cat("Calculations from time", 1, "to", 960*deltaT, "success .....\n")

         for(s in 2:sim_number) {

            error_test = file.exists(error_file)
            #################
            if(isTRUE(error_test)){

               error_msg = readLines(error_file, n = -1L, encoding = "unknown")
               error_msg = paste(error_msg, collapse = "")
               cat(error_msg, ".....\n")
               return(invisible(error_msg))


            }  else {

               sim_index = s

               beginTnew = ((sim_index-1)*960)

               if(s < sim_number){
                  endTnew =  sim_index*960
               } else {
                  endTnew = nrow(atm.bc.data)
               }

               sim_times_s = seq((beginTnew + 1), endTnew)

               sim_folder = paste("sim", s, sep = "")

               atm_bc_data_s = atm.bc.data[sim_times_s, ]

               cat("Calculating times", ceiling(beginTnew*deltaT), "to",
                   endTnew*deltaT, "\n")

               write.ini.cond(project.path, profile.depth = profile.depth,
                              pr.vec = pressure_vec)

               write.print.times(project.path, tmin = beginTnew*deltaT, tmax = endTnew*deltaT,
                                 tstep = deltaT, TimeUnit = TimeUnit)

               write.atmosph.in(project.path, maxAL = nrow(atm_bc_data_s), deltaT = deltaT,
                                atm.bc.data = atm_bc_data_s)

               call.H1D(project.path, hydrus.path = hydrus.path, show.output = show.output)


               sim_out_dir = file.path(project.path, sim_folder)
               if(!dir.exists(sim_out_dir)) dir.create(sim_out_dir)

               sim_s_files = list.files(project.path, include.dirs = F, full.names = T)
               sapply(sim_s_files, FUN = file.copy, to = sim_out_dir)

               #################
               options(warn = -1)
               h1d_output =    data.table::fread(input = file.path(project.path, "Nod_Inf.out"),
                                                 fill = TRUE, blank.lines.skip = FALSE, skip = 10)

               time_ind = grep("Time:", h1d_output[["Node"]])
               to_skip = time_ind[length(time_ind)]+2

               head_profile = h1d_output[to_skip:nrow(h1d_output), c("Node", "Depth", "Head")]
               head_profile = as.data.frame(apply(head_profile, 2, as.numeric))
               head_profile = na.omit(head_profile)
               pressure_vec = head_profile$Head

               # sapply(list.files(project.path, pattern = "\\.OUT|\\.out", full.names = T), file.remove)

               options(warn = 0)



               cat("simulation from time", ceiling(beginTnew*deltaT), "to",
                   endTnew*deltaT, "success .....\n")

               next;

            }


         }

         cat("combining all calculations .....\n")
         #####
         join.output.files(project.path)

         sim_dirs = dir(project.path, pattern = "sim", full.names = TRUE)
         mapply(FUN = unlink, sim_dirs, recursive = T, force = T)

      }
      cat("Calculations have finished successfully.")
   }

}
