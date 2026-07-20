html files in this folder are generated from templates and build system in repo_root/emails

Psiphon change - the templates in repo_root/emails have been edited and the html files regenerated, so these regenerated files have custom Psiphon content. To make custom changes to these email template files, make changes in the templates in repo_root/emails and run `make` in repo_root/emails to generate the updated files.

Psiphon change - alert_notification.html and alert_notification.txt do not have corresponding template files in repo_root/emails so those files are not generated from a template and changes should be made to them directly in this folder.
