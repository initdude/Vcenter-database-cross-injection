# Vcenter-database-cross-injection
one of the biggest Challenge during our projects was happend during the Update of vCenter 6.7 to 7.3 and the 8.3 suddenly our upgrade process hit with an error!!!! vcenter could not run drs!!!
upgrade interrupted and everything gone!!! with about 370 Server that managed by vCenter we had just a damaged vcenter appliance that has no DRS and HA!!!!

so we findout that the promble was in the Hosts Esxi version, then we update the hosts esxi to 7.3 then ofcourse the distributed switch version, then we decide to restart the vcenter machine to take effect, and guess what!! even that sick vcenter appliance is gone!!!
that was a disaster so we try many many ways, but we've got no answer 
the last way was to dump the vcenter's database through ssh, install a new fresh version of vcenter and then inject the database in it! 
it was so challenging but finally it works.
we saved a enterprise environment from a huge downtime.
here is how.
