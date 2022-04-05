import os
import json
from packaging import version

pubspec =os.path.join(os.getcwd(),"pubspec.yaml")
mainEngine =os.path.join(os.getcwd(),"lib","controller","Engine.dart")

v0Path=os.path.join(os.getcwd(),"syami_Updates","V0.json")
# Opening JSON file
f0 = open(v0Path)

# returns JSON object as
# a dictionary
data0 = json.load(f0)


lastVersion0=data0[0]["Version"]


usedVersion=version.parse(lastVersion0)

with open(pubspec) as file:
    lines=[]
    for line in file:
        if line.startswith('version:'):
            line='version: '+str(usedVersion)+'+1'+'\n'
            print(line)
            lines.append(line)
        else:
            lines.append(line)
#print(lines)

with open(pubspec, 'w') as file:
    for line in lines:
        file.write(line)


with open(mainEngine) as file:
    lines=[]
    for line in file:
        
        if line.startswith('  String appVersion = '):
            line=f'  String appVersion = "{str(usedVersion)}";'+'\n'
            print(line)
            lines.append(line)
        else:
            lines.append(line)
#print(lines)

with open(mainEngine, 'w') as file:
    for line in lines:
        file.write(line)