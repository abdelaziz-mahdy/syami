
cd syami_Updates

call gsutil -m cp -r SyamiV0.json gs://anime-293309.appspot.com/
call gsutil setmeta -r -h "Cache-control:private, max-age=0" gs://anime-293309.appspot.com/SyamiV0.json
call timeout 20




