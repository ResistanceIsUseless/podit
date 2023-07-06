# podit
Pod thats audits the kubernetes or container environment using known container auditing tools with flask as a wrapper to create API endpoints.

Current Tools:
- [kubeaudit](https://github.com/Shopify/kubeaudit)
- [kubescape](https://github.com/kubescape/kubescape)
- [linPEAS](https://github.com/carlospolop/PEASS-ng)
- [nuclei](https://github.com/projectdiscovery/nuclei)
- [docker-bench-security](https://github.com/docker/docker-bench-security)

todo:
- fix kubeaudit
- update code to correctly wrap all cli commands
- have nuclei to have naaubu parse ports
- container to run certain commands on start for easy audit
- create reporting function to combine automated report
- add notify or some alerting to slack/discord
- update docker-bench-security
- look into adding addtional tools like [Cilium](https://docs.cilium.io/en/stable/overview/intro/)https://docs.cilium.io/en/stable/overview/intro/
