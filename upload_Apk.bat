call python editPubspecVersionAndMainEngine.py

call flutter clean
call flutter pub get
call flutter --no-color build apk --release

cd syami_Updates

call xcopy "G:\My Work HDD2\AndroidStudioProjects\syami\build\app\outputs\apk\release\" . /Y
echo hi
call del /f Syami.apk
echo hi2
call ren app-release.apk Syami.apk
cd avoid_updates
call gsutil -m cp -r SyamiV0.json gs://anime-293309.appspot.com/
call gsutil setmeta -r -h "Cache-control:private, max-age=0" gs://anime-293309.appspot.com/SyamiV0.json
cd..

call gsutil -m cp -r Syami.apk gs://anime-293309.appspot.com/
call gsutil setmeta -r -h "Cache-control:private, max-age=0" gs://anime-293309.appspot.com/Syami.apk

call gsutil -m cp -r SyamiV0.json gs://anime-293309.appspot.com/
call gsutil setmeta -r -h "Cache-control:private, max-age=0" gs://anime-293309.appspot.com/SyamiV0.json
call timeout 20




