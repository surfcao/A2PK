# A2PK
This MATLAS package allows you to generate stocastic Gaussin simulation at a fine-scale based on a coarse scale image of the same domain. This is done through area-to-point kriging, a co-kriging estimation where the coase-scale is view as a secondary variable which allows the construction of the cross-covariance easily. 


## Area-to-point kriging live-script
The scripts below are generated with Matlab live-script and allow your to see step by step what is A2PK and how to use it.
- [``A2PK Gaussian``](https://raphael-nussbaumer-phd.github.io/A2PK/LiveScript/A2PK_gaussian) Live Script is the easiest place to start as this guide you through the computation of the simulation
- [``A2PK Conditional Gaussian``](https://raphael-nussbaumer-phd.github.io/A2PK/LiveScript/A2PK_cond_gaussian) expend the previous Live Script with the conditional case
- [``A2PK.m``](./A2PK.m) is the matlab function file which can be used for any application.


## Application to Eletrical Resistivity Tomography (ERT)
We applied A2PK to the simulation of a fine-scale scale electrical conductivity field based on the smooth result of an inversion based on ERT. Refers to [the ERT folder](https://github.com/Raphael-Nussbaumer-PhD/A2PK/tree/master/ERT) for all the codes, and more precisely to the publish script [``script_ERT.mlx``](https://raphael-nussbaumer-phd.github.io/A2PK/ERT/script_ERT). 

This work has lead to a paper which is currently under revision. Contact me if you would like a pdf of the draft. 

## Application to Hydraulic tomography (HT)
Refers to [the HT folder](https://github.com/Raphael-Nussbaumer-PhD/A2PK/tree/master/HT), and more precisely to [the script used to generate the dataset and the result](https://github.com/Raphael-Nussbaumer-PhD/A2PK/blob/master/HT/script_elec_cond.m). I'll try to make an html page of this code soon. 
This is an ongoing research.

## Reference
Some useful readings
- Kyriakidis, Phaedon C. 2004. “A Geostatistical Framework for Area-to-Point Spatial Interpolation.” Geographical Analysis 36(3):259–89. Retrieved (http://doi.wiley.com/10.1353/geo.2004.0009).
- Yoo, E. H. and Phaedon C. Kyriakidis. 2006. “Area-to-Point Kriging with Inequality-Type Data.” Journal of Geographical Systems 8(4):357–90.
- Yoo, Eun Hye and P. C. Kyriakidis. 2008. “Area-to-Point Prediction Under Boundary Conditions.” Geographical Analysis 40(4):355–79. Retrieved (http://doi.wiley.com/10.1111/j.0016-7363.2008.00734.x).
- Yoo, E. H. and P. C. Kyriakidis. 2009. “Area-to-Point Kriging in Spatial Hedonic Pricing Models.” Journal of Geographical Systems 11(4):381–406.
- Atkinson, Peter M. 2013. “Downscaling in Remote Sensing.” International Journal of Applied Earth Observation and Geoinformation 22(1):106–14. Retrieved (http://dx.doi.org/10.1016/j.jag.2012.04.012).
- Atkinson, Peter M., Eulogio Pardo-Igúzquiza, and Mario Chica-Olmo. 2008. “Downscaling Cokriging for Super-Resolution Mapping of Continua in Remotely Sensed Images.” IEEE Transactions on Geoscience and Remote Sensing 46(2):573–80.
- Liu, X. H., P. C. Kyriakidis, and M. F. Goodchild. 2008. “Population‐density Estimation Using Regression and Area‐to‐point Residual Kriging.” International Journal of Geographical Information Science 22(4):431–47. Retrieved (http://www.tandfonline.com/doi/abs/10.1080/13658810701492225).
- Gotway, Carol A. and Linda J. Young. 2002. “Combining Incompatible Spatial Data.” Journal of the American Statistical Association 97(458):632–48. Retrieved (http://www.tandfonline.com/doi/abs/10.1198/016214502760047140).
Kyriakidis, Phaedon C. and Eun Hye Yoo. 2005. “Geostatistical Prediction and Simulation of Point Values from Areal Data.” Geographical Analysis 37(2):124–51.
