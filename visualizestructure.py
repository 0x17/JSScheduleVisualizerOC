import os
import sys
import random

def log(s): print(s + '...')

def extract_int(s): return int(float(s))
def extract_float(s): return float(s)

#def count_cond(pred, lst): return sum(1 if pred(elem) else 0 for elem in lst)
#def count_nonempty(lines): return count_cond(lambda line: len(line.strip()) > 0, lines)

VERY_TRANSPARENT = '#00000033'
SLIGHTLY_TRANSPARENT = '#00000077'

with open('myschedule.txt') as fp:
    lines = fp.readlines()
    nonempty_lines = list(filter(lambda line: len(line.strip()) > 0, lines))
    numJobs = len(nonempty_lines)
    jobs = range(1, numJobs+1)
    sts = list(map(lambda line: extract_int( line.split('->')[1] ), nonempty_lines))
    
with open('activityproperties.txt') as fp:
    lines = fp.readlines()
    durations = list(map(lambda line: extract_int(line), lines[0:numJobs]))
    demands = list(map(lambda line: extract_int(line), lines[numJobs:2*numJobs]))

random.seed(2)

def to_hex_str(v):
    return ('%X' % v).zfill(2)

def randomColor():
    r = int(random.random() * 255)
    g = int(random.random() * 255)
    b = int(random.random() * 255)
    brightness = (r + g + b) / (3.0 * 255.0)
    return {'color': '#'+to_hex_str(r)+to_hex_str(g)+to_hex_str(b), 'brightness': brightness}


def brightnessToFontColor(brightness):
    return '#000000' if brightness > 0.5 else '#ffffff'

jobTextColors = {j: randomColor() for j in jobs}

with open('jobcolors.txt', 'w') as fp:
    for j in jobs:
        fp.write(str(j) + ';' + jobTextColors[j]['color'] + ';' + brightnessToFontColor(
            jobTextColors[j]['brightness']) + '\n')

vizStr = 'digraph G {\nnode [shape=box];\nedge [color="' + SLIGHTLY_TRANSPARENT + '"];\n'

for j in jobs:
    descr = 'd=' + str(durations[j - 1]) + ',<br />k=' + str(demands[j - 1])
    vizStr += str(j) + '[label=<' + str(j) + '<br/><font point-size="8">' + descr + '</font>>'
    vizStr += ',fontcolor="' + brightnessToFontColor(jobTextColors[j]['brightness']) + '",color=blue,fillcolor="' + jobTextColors[j]['color'] + '",style=filled];\n'
    
with open('projectstructure.txt') as fp:
    lines = fp.readlines()
    for line in lines:
        if '->' in line:
            parts = line.split('->')
            pred = extract_int(parts[0])
            succ = extract_int(parts[1])
            colorAttr = ' [color="' + SLIGHTLY_TRANSPARENT + '"]'
            vizStr += str(pred) + '->' + str(succ) + colorAttr + ';\n'

vizStr += '}\n'

with open('forgviz.dot', 'w') as fp: fp.write(vizStr)

os.system('dot forgviz.dot -o forgviz.pdf -Tpdf')
