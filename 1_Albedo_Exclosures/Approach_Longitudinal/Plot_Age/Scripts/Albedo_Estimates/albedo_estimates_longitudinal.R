## Script to calculate albedo estimates for each relevant SustHerb site across all years
## This script uses the albedo model generated by Cherubini et al. (w/ 'stand age' as an input parameter)


##PACKAGES ----------------------------------------------------------------------------------------

        #Packages for general data manipulation + visualization
        library(ggplot2)
        library(dplyr)
        library(RColorBrewer)
        library(wesanderson)
        library(sp)
        library(raster)
        library(GGally)
        library(lattice)


###END PACKAGES ----------------------------------------------------------------------------------------





#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\




#INITIAL DATA IMPORT + FORMATTING ----------------------------------------------------------------------

        ## SITE DATA
        
                #Get 'cleaned' site data from adjacent 'Sites' folder
                site_data <- read.csv('1_Albedo_Exclosures/Data/SustHerb_Site_Data/cleaned_data/cleaned_data.csv', header = TRUE)
        
        
        ## SENORGE SWE/TEMP DATA (2001 - 2018 - NEED TO PULL ADDITIONAL SENORGE DATA FOR 2019 AND 2020)
        
                #Add monthly SWE averages from seNorge
                swe <- read.csv('1_Albedo_Exclosures/Universal/Output/SWE/monthly_avg_swe_mm_all_years.csv', header = TRUE)
                
                #Add monthly temperature averages from seNorge
                temps <- read.csv('1_Albedo_Exclosures/Universal/Output/Temperature/monthly_avg_temp_C_all_years.csv', header = TRUE)
                
                        #Convert temps from celsius (C) to kelvin (K)
                        for( i in 1:length(temps$X)){
                                #K = C + 273.15
                                temps[i, "Avg_Temp_C"] <- temps[i, "Avg_Temp_C"] + 273.15
                        }
                        
                        #Rename column from C to K
                        colnames(temps)[5] <- "Avg_Temps_K"
                      
                          
        #HERBIVORE DENSITY DATA
                        
                #Read in herbivore biomass data (2015) from SpatialPolygons object (isolate dataframe)
                hbiomass_shp <- shapefile("2_Albedo_Regional/Data/Herbivore_Densities/NorwayLargeHerbivores")
                        
                #Pull out dataframe
                hbiomass <- hbiomass_shp@data
                        
                #Isolate to 2015 data
                hbiomass2015<- cbind(hbiomass[,c(1:10)], hbiomass$Ms_2015, hbiomass$Rd__2015, hbiomass$R_d_2015)
                
                
        ## SUSTHERB SITE PRODUCTIVITY
                
                #Productivity Data
                productivity <- read.csv('1_Albedo_Exclosures/Data/SustHerb_Site_Data/productivity_all_sites.csv', header = TRUE)
                productivity$LocalityName <- tolower(productivity$LocalityName)
                
                #Correct LocalityName items in productivity CSV
                
                        #Didrik Holmsen
                        productivity$LocalityName[productivity$LocalityName == "didrik holmsen"] <- "didrik_holmsen"
                        
                        #Fet 3
                        productivity$LocalityName[productivity$LocalityName == "fet 3"] <- "fet_3"
                        
                        #Fritsøe 1
                        productivity$LocalityName[productivity$LocalityName == "fritsøe1"] <- "fritsoe1"
                        
                        #Fritsøe 2
                        productivity$LocalityName[productivity$LocalityName == "fritsøe2"] <- "fritsoe2"
                        
                        #Halvard Pramhus
                        productivity$LocalityName[productivity$LocalityName == "halvard pramhus"] <- "halvard_pramhus"
                        
                        #Singsaas
                        productivity$LocalityName[productivity$LocalityName == "singsås"] <- "singsaas"
                        
                        #Stangeskovene Aurskog
                        productivity$LocalityName[productivity$LocalityName == "stangeskovene aurskog"] <- "stangeskovene_aurskog"
                        
                        #Stangeskovene Eidskog
                        productivity$LocalityName[productivity$LocalityName == "stangeskovene eidskog"] <- "stangeskovene_eidskog"
                        
                        #Stig Dahlen
                        productivity$LocalityName[productivity$LocalityName == "stig dæhlen"] <- "stig_dahlen"
                        
                        #Truls Holm
                        productivity$LocalityName[productivity$LocalityName == "truls holm"] <- "truls_holm"
                
                
        ## SUSTHERB TREE SPECIES PROPORTIONS (At the PLOT level)
                        
                #Tree density data for Trøndelag, Telemark, and Hedmark
                ##NOTE: THIS DATA IS CURRENTLY LIMITED TO 2018, SINCE ADDITIONAL SENORGE DATA NEEDS TO BE PULLED TO ALLOW ANALYSIS
                ## OF 2019 AND 2020
                tree_data <- read.csv('1_Albedo_Exclosures/Universal/Output/Tree_Species_Proportions/tree_species_proportions_plot_level.csv', header = TRUE)
                tree_data <- tree_data[tree_data$Year <= 2018, 2:7]
                
                        #Filter out unused SustHerb sites
                        
                                #Convert site codes to factors
                                tree_data$LocalityCode <- as.factor(tree_data$LocalityCode)
                                site_data$LocalityCode <- as.factor(site_data$LocalityCode)
                                
                                #Get vector of levels for sites that will be used (n = 74)
                                used_sites <- levels(site_data$LocalityCode)
                                
                                #Filter tree data to used sites
                                tree_data <- tree_data[tree_data$LocalityCode %in% used_sites,]
                                tree_data$LocalityCode <- as.factor(as.character(tree_data$LocalityCode))
        
                                
#CALCULATE MONTHLY ALBEDOS #1 -----------------------------------------------------------------------------
#NOTE: This section of code calculates albedos based on stand age, but for the same years in which LiDAR data was collected for each plot
## This should allow direct comparison of the volume-based methods with age-based methods

        ##NOTE: The 'age' parameter for the albedo model is the 'Years Since Clearcut' value
                                
        #Source albedo model function
        source("3_Albedo_Model/albedo_model_age.R")
                                
        #Blank dataframe to hold final albedo values
        albedo_final <- data.frame("Age" = integer(),
                                   "Years_Since_Exclosure" = integer(),
                                   "Month" = integer(), "Year" = integer(),
                                   "Composite_Albedo" = double(),
                                   "LocalityCode" = factor(),
                                   "LocalityCode" = factor(),
                                   "Treatment" = factor())
        
        #For each LocalityCode, run albedo model function w/ relevant arguments
        for(i in 1:length(site_data$LocalityCode)){
                
                #Get relevant arguments and variables
                
                        #LocalityCode
                        a <- as.character(site_data[i, "LocalityCode"])
                        
                        #LocalityName
                        b <- site_data[i, "LocalityName"]
                        
                        #Treatment (open or exclosure)
                        c <- site_data[i, "Treatment"]
                
                        #First available year of tree data for this site
                        first_year <- tree_data$Year[tree_data$LocalityCode == a][[1]]
                        
                        #Last available year of tree data for this site
                        last_year <- tree_data$Year[tree_data$LocalityCode == a][[length(tree_data$Year[tree_data$LocalityCode == a])]]
                        
                        #Clearcut year
                        clearcut_year <- site_data$Clear.cut[site_data$LocalityCode == a]
                        
                        #Years since exclosure
                        exclosure_year <- site_data$Year.initiated[site_data$LocalityCode == a]
                        
                #Define dataframe to hold albedo estimates for site i (across all years)
                site_all_years <- data.frame("Month" = factor(),
                                             "Composite_Albedo" = double(),
                                             "LocalityCode" = factor(),
                                             "LocalityName" = factor(),
                                             "Treatment" = factor(),
                                             "Age" = integer(),
                                             "Years_Since_Exclosure" = integer(),
                                             "Year" = integer())
                
                #Loop from first year to last year and calculate albedo for each
                for(j in first_year:last_year){

                        #AGE
                        
                                #Get age (current year of tree data - year of clearcutting)
                                a_age <- j - clearcut_year
                                
                                #Get years since exclosure (current year - initiation of exclosure)
                                a_excl <- j - exclosure_year
                                
                        #TREE SPECIES PROPORTIONS
                                
                                #Spruce %
                                a_spruce <- tree_data$Prop_spruce[tree_data$LocalityCode == a & tree_data$Year == j]
                                
                                #Pine %
                                a_pine <- tree_data$Prop_pine[tree_data$LocalityCode == a & tree_data$Year == j]
                                
                                #Birch/Deciduous %
                                a_birch <- tree_data$Prop_birch[tree_data$LocalityCode == a & tree_data$Year == j]
                        
                                
                        #SENORGE SWE + TEMPERATURE
                                
                                #NOTE: The SWE and Temp datasets only have data for the 'browsed' plots
                                ## However, it is assumed that the exclosures have the same SWE & Temp data
                                ### The code below handles this issue - for all exclosures, SWE/Temp data
                                #### from open plots is used
                        
                                #If exclosure, get LocalityCode for corresponding open plot
                                if(c == "exclosure"){
                                        
                                        d <- site_data$LocalityCode[site_data$LocalityName == b & site_data$Treatment == 'open']
                                        
                                        #Temps
                                        a_temps <- temps$Avg_Temps_K[temps$LocalityCode == d & temps$Year == j]
                                        
                                        #SWE
                                        a_swe <- swe$SWE_mm[swe$LocalityCode == d & swe$Year == j]
                                        
                                } else if (c == "open"){
                                        
                                        #Temps
                                        a_temps <- temps$Avg_Temps_K[temps$LocalityCode == a & temps$Year == j]
                                        
                                        #SWE
                                        a_swe <- swe$SWE_mm[swe$LocalityCode == a & swe$Year == j]
                                        
                                }
                                
                                
                        #CALCULATE ALBEDO
                                
                                #Run function with necessary arguments
                                year_df <- albedoAge(site = a,
                                                     localityName = b,
                                                     treatment = c,
                                                     age = a_age,
                                                     temp = a_temps,
                                                     swe = a_swe,
                                                     spruce = a_spruce,
                                                     pine = a_pine,
                                                     birch = a_birch)
                                
                                #Add year column (with current year)
                                year_df$Year <- j
                                
                                #Add 'age' column (year since clearcut)
                                year_df$Age <- a_age
                                
                                #Add 'years since exclosure' column
                                year_df$Years_Since_Exclosure <- a_excl
                                
                                site_all_years <- rbind(site_all_years, year_df)
                                
                }
                
                #Bind all years for site i to final df
                albedo_final <- rbind(albedo_final, site_all_years)        
        }
        
#END CALCULATE MONTHLY ALBEDOS -------------------------------------------------------------------------
        
        
        
        
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\




#CALCULATE ALBEDO DIFFERENCE -----------------------------------------------------------------------------
        
        #Get difference between open plots and exclosures for each site (to plot)

        #Aggregate
        albedo_diff <- aggregate(albedo_final$Composite_Albedo,
                                 by = list(Month = albedo_final$Month,
                                           Year = albedo_final$Year,
                                           LocalityName = albedo_final$LocalityName,
                                           Age = albedo_final$Age,
                                           Years_Since_Exclosure = albedo_final$Years_Since_Exclosure),
                                 FUN = diff)
        
        names(albedo_diff)[6] <- "Albedo_Diff_Excl_Open"
        albedo_diff$Albedo_Diff_Excl_Open <- as.numeric(albedo_diff$Albedo_Diff_Excl_Open)
        
        
#END CALCULATE ALBEDO DIFFERENCE -------------------------------------------------------------------------
        
        
        

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
        
        
        
#DATA EXPLORATION -----------------------------------------------------------------------------
        
        ##Coalesce all data into single dataframe (for analysis)
        
                #Add new columns
                albedo_final$Region = ''
                albedo_final$Productivity_Index = ''
                albedo_final$Moose_Density = ''
                albedo_final$Red_Deer_Density = ''
                albedo_final$Roe_Deer_Density = ''
                
                #Define 'model_data' df for analysis
                model_data <- albedo_final
                
                #Add relevant data for new columns
                for(i in 1:nrow(model_data)){
                        
                        print(i)
                        
                        #Get locality code
                        loc <- model_data[i, "LocalityCode"]
                        
                        #Get site name
                        sn <- model_data[i, "LocalityName"]
                        
                        #Get kommune number
                        kn <- site_data$DistrictID[site_data$LocalityCode == loc]
                        
                        #Get corresponding 'region' from site data & add
                        region <- site_data$Region[site_data$LocalityCode == loc]
                        model_data[i, "Region"] <- region
                        
                        #Get corresponding 'productivity' & add
                        prod <- productivity$Productivity[productivity$LocalityName == sn]
                        model_data[i, "Productivity_Index"] <- prod
                        
                        #Get 2015 herbivore densities and add
                        
                                #Moose density
                                md <- hbiomass2015$`hbiomass$Ms_2015`[hbiomass2015$KOMMUNE == kn]
                                model_data[i, "Moose_Density"] <- md
                                
                                #Red deer density
                                rd <- hbiomass2015$`hbiomass$Rd__2015`[hbiomass2015$KOMMUNE == kn]
                                model_data[i, "Red_Deer_Density"] <- rd
                                
                                #Roe deer density
                                rdd <- hbiomass2015$`hbiomass$R_d_2015`[hbiomass2015$KOMMUNE == kn]
                                model_data[i, "Roe_Deer_Density"] <- rdd
                        
                }
                
                model_data$Treatment <- as.factor(model_data$Treatment)
                model_data$Productivity_Index <- as.numeric(model_data$Productivity_Index)
                model_data$LocalityCode <- as.character(model_data$LocalityCode)
                model_data$Moose_Density <- as.numeric(model_data$Moose_Density)
                model_data$Red_Deer_Density <- as.numeric(model_data$Red_Deer_Density)
                model_data$Roe_Deer_Density <- as.numeric(model_data$Roe_Deer_Density)
                
        
        #YEARS SINCE EXCLOSURE ----------------------------------------------------------------------------------------
        
                #Years since exclosure vs. albedo difference (exclosure - open), faceted by month
   
                        #Plot
                        yse_plot <- ggplot(data = albedo_diff, aes(x = Years_Since_Exclosure, y = Albedo_Diff_Excl_Open)) +
                                        geom_point() +
                                        geom_jitter(width = 0.25) +
                                        facet_wrap(.~Month, ncol = 4) +
                                        geom_smooth(method = lm) +
                                        scale_x_discrete(limits=c(1:10)) + 
                                        ggtitle("Monthly differences in albedo between exclosures\n and open plots (using age-based albedo model)") +
                                        labs(x = "Years Since Exclosure", y = "Albedo Difference (Excl.-Open)") +
                                        scale_fill_manual(values=wes_palette(n=2, name="FantasticFox1")) +
                                        theme(plot.title = element_text(hjust = 0.5, size = 60, margin = margin(t = 40, b = 40)),
                                                axis.text.x = element_text(size = 20, margin = margin(t=16)),
                                                axis.text.y = element_text(size = 20, margin = margin(r=16)),
                                                axis.title.x = element_text(size = 50, margin = margin(t=40, b = 40)),
                                                axis.title.y = element_text(size = 50, margin = margin(r=40)),
                                                strip.text.x = element_text(size = 20))
                                        
                                        
                #Faceted plot, grouped into 3 categories of productivity
                ##This might allow us to see if sites with high productivity have different trends than sites with low productivity
                
                        #Add productivity data to df
                                
                                #Create placeholder columns
                                albedo_diff$Productivity_Index <- ''
                                albedo_diff$Productivity_Class <- ''
                                
                                for( i in 1:nrow(albedo_diff) ){
                                        
                                        #Get site name
                                        sn <- albedo_diff[i, "LocalityName"]
                                        
                                        #Get corresponding productivity index
                                        pr <- productivity$Productivity[productivity$LocalityName == sn]
                                        
                                        #Add productivity index to df
                                        albedo_diff[i, "Productivity_Index"] <- pr
                                        
                                        #Group into 3 productivity classes
                                        if( pr <= 0.333 ){
                                                pc <- 1
                                        } else if ( pr > 0.333 & pr <= 0.666 ){
                                                pc <- 2
                                        } else if ( pr > 0.666 ){
                                                pc <- 3
                                        }
                                        
                                        #Add productivity class
                                        albedo_diff[i, "Productivity_Class"] <- pc
                                        
                                }
                                
                        #Plot
                        yse_plot_group <- ggplot(data = albedo_diff, aes(x = Years_Since_Exclosure, y = Albedo_Diff_Excl_Open, group = Productivity_Class, color = Productivity_Class)) +
                                geom_point() +
                                geom_jitter(width = 0.25) +
                                facet_wrap(.~Month, ncol = 4) +
                                geom_smooth(method = lm) +
                                scale_x_discrete(limits=c(1:10)) + 
                                ggtitle("Monthly differences in albedo between exclosures and open plots,\ngrouped by productivity class (using age-based albedo model)") +
                                labs(x = "Years Since Exclosure", y = "Albedo Difference (Excl.-Open)") +
                                scale_fill_manual(values=wes_palette(n=2, name="FantasticFox1")) +
                                theme(plot.title = element_text(hjust = 0.5, size = 60, margin = margin(t = 40, b = 40)),
                                      legend.title = element_text(size = 30),
                                      legend.text = element_text(size = 30),
                                      axis.text.x = element_text(size = 20, margin = margin(t=16)),
                                      axis.text.y = element_text(size = 20, margin = margin(r=16)),
                                      axis.title.x = element_text(size = 50, margin = margin(t=40, b = 40)),
                                      axis.title.y = element_text(size = 50, margin = margin(r=40)),
                                      strip.text.x = element_text(size = 20)) +
                                scale_color_discrete(name = "Productivity Index", labels = c("0-0.3", "0.3-0.6", "0.6-1"))
        
                        
        #AGE (YEARS SINCE CLEARCUT) ---------------------------------------------
                        
                #Plot
                yscc_plot <- ggplot(data = albedo_diff, aes(x = Age, y = Albedo_Diff_Excl_Open)) +
                        geom_point() +
                        geom_jitter(width = 0.25) +
                        facet_wrap(.~Month, ncol = 4) +
                        geom_smooth(method = lm) +
                        scale_x_discrete(limits=c(1:18)) + 
                        ggtitle("Monthly differences in albedo between exclosures\n and open plots (using age-based albedo model)") +
                        labs(x = "Years Since Clearcut", y = "Albedo Difference (Excl.-Open)") +
                        scale_fill_manual(values=wes_palette(n=2, name="FantasticFox1")) +
                        theme(plot.title = element_text(hjust = 0.5, size = 60, margin = margin(t = 40, b = 40)),
                              axis.text.x = element_text(size = 20, margin = margin(t=16)),
                              axis.text.y = element_text(size = 20, margin = margin(r=16)),
                              axis.title.x = element_text(size = 50, margin = margin(t=40, b = 40)),
                              axis.title.y = element_text(size = 50, margin = margin(r=40)),
                              strip.text.x = element_text(size = 20))
                
                
                #Plot
                yscc_plot_group <- ggplot(data = albedo_diff, aes(x = Age, y = Albedo_Diff_Excl_Open, group = Productivity_Class, color = Productivity_Class)) +
                        geom_point() +
                        geom_jitter(width = 0.25) +
                        facet_wrap(.~Month, ncol = 4) +
                        geom_smooth(method = lm) +
                        scale_x_discrete(limits=c(1:18)) + 
                        ggtitle("Monthly differences in albedo between exclosures and open plots,\ngrouped by productivity class (using age-based albedo model)") +
                        labs(x = "Years Since Clearcut", y = "Albedo Difference (Excl.-Open)") +
                        theme(plot.title = element_text(hjust = 0.5, size = 60, margin = margin(t = 40, b = 40)),
                              legend.title = element_text(size = 30),
                              legend.text = element_text(size = 30),
                              axis.text.x = element_text(size = 20, margin = margin(t=16)),
                              axis.text.y = element_text(size = 20, margin = margin(r=16)),
                              axis.title.x = element_text(size = 50, margin = margin(t=40, b = 40)),
                              axis.title.y = element_text(size = 50, margin = margin(r=40)),
                              strip.text.x = element_text(size = 20)) +
                        scale_color_discrete(name = "Productivity Index", labels = c("0-0.3", "0.3-0.6", "0.6-1"))
                yscc_plot_group
        
#END DATA EXPLORATION -------------------------------------------------------------------------
        
        
        
        
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
        
        
        
        
#WRITE OUTPUT ------------------------------------------------------------------------------
        
        #Write CSV of All Albedo Estimates to Output Folder
        write.csv(model_data, file = '1_Albedo_Exclosures/Approach_Longitudinal/Plot_Age/Output/Albedo_Estimates/albedo_estimates_approach_longitudinal_age.csv', row.names = TRUE)
        
        #Write CSV of Albedo Differences to Output Folder
        write.csv(albedo_diff, file = '1_Albedo_Exclosures/Approach_Longitudinal/Plot_Age/Output/Albedo_Estimates/albedo_differences_approach_longitudinal_age.csv', row.names = TRUE)
        
        #Export YSE plot #1 as PNG
        png(filename = "1_Albedo_Exclosures/Approach_Longitudinal/Plot_Age/Output/Albedo_Estimates/approach_longitudinal_stand_age_yse_1.png",
            width = 2000,
            height = 2300,
            units = "px",
            bg = "white")
        yse_plot
        dev.off()
        
        #Export YSE plot #2 as PNG
        png(filename = "1_Albedo_Exclosures/Approach_Longitudinal/Plot_Age/Output/Albedo_Estimates/approach_longitudinal_stand_age_yse_2.png",
            width = 2400,
            height = 2300,
            units = "px",
            bg = "white")
        yse_plot_group
        dev.off()
        
        #Export YSCC plot #1 as PNG
        png(filename = "1_Albedo_Exclosures/Approach_Longitudinal/Plot_Age/Output/Albedo_Estimates/approach_longitudinal_stand_age_yscc_1.png",
            width = 2000,
            height = 2300,
            units = "px",
            bg = "white")
        yscc_plot
        dev.off()
        
        #Export YSCC plot #2 as PNG
        png(filename = "1_Albedo_Exclosures/Approach_Longitudinal/Plot_Age/Output/Albedo_Estimates/approach_longitudinal_stand_age_yscc_2.png",
            width = 2400,
            height = 2300,
            units = "px",
            bg = "white")
        yscc_plot_group
        dev.off()
        
#END WRITE OUTPUT --------------------------------------------------------------------------      