extensions [ nw table ]
globals
[
  possible-traditions  ;; List  List of the possible traditions that exists. It is a list of numbers where each number is a tradition
  half-traditions      ;; List  List of 9 or less possible traditions. It is used to set the maximum number of traditions
  max-degree           ;; Int  The max degree in the system. It is used to set the maximum number of traditions that some community has
  final-freq           ;; Dict. Dictionary of lists that saves the frequence of a tradidion
]
breed [importants important]
breed [mortals mortal]
turtles-own
[
  with-tradition?      ;; Boolean  To know if it already has an art tradition
  styles               ;; Int      The number of styles that a community/house has
  list-traditions      ;; List     list of the traditions that it has
  copy-style           ;; Int      The variable that is going to store the temporal style that will be copied
  inventor             ;; Int      Variable to see if it has invented or not and how many inventions it has
  degree               ;; Int      The degree of the house
  eigen-centrality     ;; Float    Eigenvector centrality
]

to setup
  ca
  set-default-shape importants "star"
  set-default-shape mortals "wheel"
  set possible-traditions (range 1 (traditions + 1))
  create-comunities
  if network-type = "Watts-Strogatz small world" [
  ask n-of 2 turtles [;create-link-with one-of other turtles
      set degree degree + 1]
  ]
  set max-degree max [degree] of turtles
  ask turtles [give-breeds]
  count-traditions
  reset-ticks
end

to go
  ask importants [copy-importants]
  ask mortals [copy-mortals]
  if length possible-traditions > 0 [
    ask one-of turtles with [breed = importants] [create-art]
  ]if length possible-traditions > 0 [
    ask one-of turtles with [breed = mortals] [create-art]
  ]
  count-traditions
  if (all? turtles [with-tradition? = True]) [stop]

  tick
end

to create-comunities       ;; Here, I am creating the communities in the map
  ;; Here is the small-world network
  if network-type = "Watts-Strogatz small world" [
    nw:generate-watts-strogatz turtles links agents 2 0.01 [
      set degree count my-links
      properties
    ]
  ]
  ;; Here is the random network
  if network-type = "Random" [
    nw:generate-random turtles links agents 0.15 [
      set degree count my-links
      properties
    ]
  ]
  ;; Here is the preferential attatchment network
  if network-type = "Preferential attatchment" [
    nw:generate-preferential-attachment turtles links agents 2 [
      set degree count my-links
      properties
    ]
  ]
  ;; Here is another small world network
  if network-type = "Small World" [
    nw:generate-small-world turtles links 7 7 2.0 False [
      set degree count my-links
      properties
    ]
  ]
  ;; The layout
  repeat 30 [ layout-spring turtles links 0.1 5 5 ]


end

to properties              ;; For the properties of the communities
  ;; separate the turtles spatially
  setxy random-xcor random-ycor

  ;; Set of color
  set color white

  ;; set of characteristics
  set with-tradition? False
  set styles 0
  set list-traditions []
  ;;set max-traditions one-of half-traditions
  set inventor 0
  set eigen-centrality nw:eigenvector-centrality

end

to give-breeds             ;; To clasify and create the breeds according to the network structure and the degree.
;; The possible breeds depend on the network structure and the max degree of that configuration. It is relative to the network structure
;; because I wanted to impose few importants and a lot of mortals. In some netowkrs (such as Watts-Strogatz small world)
;; the "max degree - 1" was shared by lots of agents so I let only "max degree". In others, such as Preferential attatchment, the "max degre - 1" was only shared by one
;; so I rested 3 instead.


  if network-type = "Watts-Strogatz small world"[
    ifelse degree >= max-degree [set breed importants] [set breed mortals]]
  if network-type = "Preferential attatchment" [
    ifelse degree >= max-degree [set breed importants] [set breed mortals]]
  if network-type = "Random" [
    ifelse degree >= max-degree [set breed importants] [set breed mortals]]
  if network-type = "Small World"[
    ifelse degree >= max-degree [set breed importants] [set breed mortals]]
end

to count-traditions        ;; To count the number of traditions that some community has
  ask turtles
  [
   set styles length list-traditions
   if styles > 0 [
      set with-tradition? true
      if (color != blue) [
        if color != green [
          set color red]]]
  ]
end

to copy-importants         ;; Mechanism for importants only
    if any? link-neighbors with [with-tradition?]
        [ if random-float 1 < important-contagion
        [ set copy-style one-of [list-traditions] of one-of link-neighbors with [with-tradition?]
          if not member? copy-style list-traditions [
            set list-traditions lput copy-style list-traditions]
  ] ]


end

to copy-mortals            ;; Mechanism for mortals only
    ;; ifelse styles < max-traditions [
    let important-neighbors link-neighbors with [breed = importants]
    let mortal-neighbors link-neighbors with [breed = mortals]
    if any? link-neighbors with [with-tradition?]
      [ ifelse any? important-neighbors with [with-tradition?] [  ;; When having at least one important neighbor with tradition
        ifelse random-float 1 < influenciability [
          if random-float 1 < mortal-to-important
          [ let important-neighbors-with-tradition important-neighbors with [with-tradition?]
            set copy-style one-of [list-traditions] of one-of important-neighbors-with-tradition
            if not member? copy-style list-traditions [
              set list-traditions lput copy-style list-traditions]
        ]] [
            if random-float 1 < mortal-contagion
            [ let mortal-neighbors-with-tradition mortal-neighbors with [with-tradition?]
              if  any? mortal-neighbors-with-tradition [
              set copy-style one-of [list-traditions] of one-of mortal-neighbors-with-tradition
              if not member? copy-style list-traditions [
              set list-traditions lput copy-style list-traditions]]
            ]
        ]] [                                                     ;; When having only mortal neighbors
        if random-float 1 < mortal-contagion
        [ let mortal-neighbors-with-tradition mortal-neighbors with [with-tradition?]
          set copy-style one-of [list-traditions] of one-of mortal-neighbors-with-tradition
          if not member? copy-style list-traditions [
            set list-traditions lput copy-style list-traditions]
         ]
       ]
     ]



end

to create-art              ;; To create an art tradition
    if random-float 1 < create-probability
            [ set list-traditions lput first possible-traditions list-traditions
              set possible-traditions but-first possible-traditions
              set color green
              set inventor inventor + 1 ]

end

to reset-diffusion
  clear-plot
  ask turtles [
  ;; Set of color
  set color white

  ;; set of characteristics
  set with-tradition? False
  set styles 0
  set list-traditions []
  set inventor 0
  set eigen-centrality nw:eigenvector-centrality
  set copy-style 0
  ]
  set possible-traditions (range 1 (traditions + 1))
  ;;ask n-of initial-creators turtles [
    ;set color red
    ;set list-traditions lput first possible-traditions list-traditions
    ;set possible-traditions but-first possible-traditions
  ;]
end
@#$#@#$#@
GRAPHICS-WINDOW
246
11
787
449
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-20
20
-16
16
0
0
1
ticks
30.0

SLIDER
21
198
193
231
agents
agents
0
100
68.0
1
1
NIL
HORIZONTAL

BUTTON
15
11
78
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
12
123
209
168
network-type
network-type
"Random" "Watts-Strogatz small world" "Preferential attatchment" "Small World"
1

BUTTON
16
59
79
92
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
21
247
193
280
traditions
traditions
0
100
24.0
1
1
NIL
HORIZONTAL

SLIDER
20
299
192
332
initial-creators
initial-creators
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
18
349
190
382
create-probability
create-probability
0
1
1.0
0.005
1
NIL
HORIZONTAL

SLIDER
810
11
982
44
important-contagion
important-contagion
0
1
0.85
0.05
1
NIL
HORIZONTAL

SLIDER
812
65
984
98
mortal-contagion
mortal-contagion
0
1
0.005
0.005
1
NIL
HORIZONTAL

SLIDER
812
120
984
153
influenciability
influenciability
0
1
0.95
0.05
1
NIL
HORIZONTAL

PLOT
1004
13
1333
224
plot 1
# Traditions per house
Frequency
1.0
15.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [styles] of turtles"

SLIDER
812
171
984
204
mortal-to-important
mortal-to-important
0
1
0.005
0.005
1
NIL
HORIZONTAL

BUTTON
107
37
220
70
NIL
reset-diffusion
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model was made for the class of Complex Systems I.
It is a model that tries to replicate the dynamics that may be relevant to understand the distribution of art traditions in Maori community according to Neich(1993).

At its core, it works as a difussion network with just a few different things. The main idea is that some communities, due to social processes clarified in the book, started to decorate their reunion houses with designs that are called "art traditions" by Neich. He collected some data about it (though no so extensive nor clear) to talk about the distribution of the number of houses with one, two, three... etc traditions. 

The main idea is that, although some of them were created, other traditions were copied. The model simulates the difussion of those traditions among the community. I used the book PAINTED HISTORIES: EARLY MĀORI FIGURATIVE PAINTING by Roger Neich to create the model (because is the only book about that topic).


## HOW IT WORKS

Set: At the beginig it creates the number of communities that we want using one of the four structures of networks that are possible and, ramdomly, three of those communities "create" a tradition. 
Every community counts its degree (number of links that it has) and those that have the biggest degree (two or three communities) are selected as important, the rest are selected as "mortals".
The maximum number of traditions is set 

Go: In each cycle after the "set" each community has certain probability to copy one random tradition of one neighbor. This probability is related to its breed (important or mortal). At the end, one community, selected randomly, creates a tradition.
To end the of the cycle, every community counts its traditions and then if there is at least one without tradition, it goes again.

It stops when every community has at least one tradition.


## HOW TO USE IT

Network: The network-type parameter determines the structure of the network for the model. It has for types of networks: random, preferential attatchment, small world and watson-strogatz small world. You can try different structures of networks to see the difference in the distribution of the art traditions at the end of the simulation
Agents: Each agent is a community so you can change the number of communities in the model to see the impact of that.
Traditions: It determines the max number of art traditions in the system.
Inital Creators: It determines the number of communities that start with a new tradition.
Create Probability: It controls how frequent traditions are created.
Important contagion: The probability that an agent with breed important copies other art tradition
Mortal contagion: Probability that a mortal agent copies an art tradition from another mortal
Influenciability: Probability that a mortal WANTS TO COPY from an important
Mortal to important: Probability  that a mortal copies from an important

The button "reset-difussion", resets the characteristics of the turtles without changing the network, and thus the breeds. It is used as an experimental tool, looking for repetition within the same network configurations. 

The plot shows the frequency of the number of traditions per community. In other words, it counts how many communities have only 3 traditions, or only 1, or only 10. 

## THINGS TO NOTICE

The last time I tried and noticed that:
1. The density of the network affects the velocity of the diffusion. So, the structure is quite related to the density in this part.
2. Parameters such as the probability of the rest of contagions, at the right of the network, affects strongly the result. I decided to use that configuration because it was the only one that ended with something close to the original in Neich (1993)
3. The number of communitites and max art traditions was parametrized based on the data. The other parameters were gotten based on experimentation.
4. Different values of create-probability lead to different distribution patterns. It is interesting to note that with a create probability < 0.8, the distribution at the end with the other same configurations is different from the one obtained in the real world. We can argue that it was a time with a lot of creativit and innovation.


## THINGS TO TRY

1. See if the effect is different with more communitites but the same other parameters.
2. See if the breeds really matter. Play with the contagion parameters to see if that the breeds are pointing to some social relevant aspects or just it can be explained just by the network structure.
3. Try another initial creators to see if those initial conditions affect the result of the system

## EXTENDING THE MODEL

It is obvious that this model is not so close to the original dynamic. I may list some arguments in that direction:
1. The stop criteria is quite arbirtrary and it does not came from the data
2. Without it, in some point, every community would have the same traditions.

So, in that part, it would be interesting to go beyond that and, using more bibliography, construct some rules to stop or change the dynamic of "infection". The social part is quite important to understand this difussion. The interesting dynamic seen in Neich (1993) can be due to some rule (related to the status of the community or the kinship) that affects the velocity or the contagion directly.

On the other hand, the links, as said before, are undirected. It can be possible that directed links (and rules based on ethnography to sustain that decision) give insight into the nature of the phenomena. 

The netwokr charactersitics of this phenomena were not so explored. Another networks related measures may be used to define whether or not the diffusion is affected by social characterstics related do the structure of the network

## NETLOGO FEATURES


## RELATED MODELS

I am currently working on an agrobiodiversity model generating a kinship network. 
I had also the idea based on an agent based model of agrobiodivesity by Sanches (2019)

## CREDITS AND REFERENCES

Neich, 1993. Painted Histories
Sanhez, 2019. Modelagem Baseada em Agentes para o estudo da Agrobiodiversidade em Sistemas Agrícolas Tradicionais
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="3 networks. Frequency" repetitions="150" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [styles = 1]</metric>
    <metric>count turtles with [styles = 2]</metric>
    <metric>count turtles with [styles = 3]</metric>
    <metric>count turtles with [styles = 4]</metric>
    <metric>count turtles with [styles = 5]</metric>
    <metric>count turtles with [styles = 6]</metric>
    <metric>count turtles with [styles = 7]</metric>
    <metric>count turtles with [styles = 8]</metric>
    <metric>count turtles with [styles = 9]</metric>
    <metric>count turtles with [styles = 10]</metric>
    <metric>count turtles with [styles = 11]</metric>
    <metric>count turtles with [styles = 12]</metric>
    <metric>count turtles with [styles = 13]</metric>
    <enumeratedValueSet variable="mortal-contagion">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="important-contagion">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-creators">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;Watts-Strogatz small world&quot;"/>
      <value value="&quot;Random&quot;"/>
      <value value="&quot;Preferential attatchment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influenciability">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="create-probability">
      <value value="0.91"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agents">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="art-stiles">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortal-to-important">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Normal try" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [styles = 1]</metric>
    <metric>count turtles with [styles = 2]</metric>
    <metric>count turtles with [styles = 3]</metric>
    <metric>count turtles with [styles = 4]</metric>
    <metric>count turtles with [styles = 5]</metric>
    <metric>count turtles with [styles = 6]</metric>
    <metric>count turtles with [styles = 7]</metric>
    <metric>count turtles with [styles = 8]</metric>
    <metric>count turtles with [styles = 9]</metric>
    <metric>count turtles with [styles = 10]</metric>
    <metric>count turtles with [styles = 11]</metric>
    <metric>count turtles with [styles = 12]</metric>
    <metric>count turtles with [styles = 13]</metric>
    <enumeratedValueSet variable="mortal-contagion">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="important-contagion">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-creators">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;Watts-Strogatz small world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influenciability">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="create-probability">
      <value value="0.91"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agents">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="art-stiles">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mortal-to-important">
      <value value="0.005"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
