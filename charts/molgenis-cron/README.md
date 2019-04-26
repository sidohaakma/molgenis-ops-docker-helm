# MOLGENIS Kubernetes cron-jobs
You can define cronjobs in Kubernetes.  

These are implemented right now:
- [cleanup of previews](#cleanup)

## Cleanup
To prevent to many previews begin up at the same time we developed a cronjob to delete them. Each night the cronjob deletes the open previews.