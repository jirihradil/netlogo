breed [tables table]
breed [guests guest]
breed [waiters waiter]
breed [kitchens kitchen]
breed [entrances entrance]

tables-own [places free-places orders meals]

;host:
;state je stav hosta, v ktere casti flow navstevy se nachazi
; 0 coming
; 1 seating
; 2 ordering
; 3 waiting
; 4 eating
; 5 wanna pay
; 6 leaving
; 7 left
;choosed-table je vybrany stul, ke kteremu si jde sednout
;time je cas hosta - pocet ticku, ktere mu narustaji od prichodu
;meal je jidlo, ktere host ji
;choosed-exit je zvoleny vychod, kterym chce odejit
guests-own [state choosed-table time meal choosed-exit]

;cisnik
;server-tables je seznam stolu, ktere obsluhuje
;orders-to-kitchen je seznam objednavek, ktere nese od stolu do kuchyne
;orders-to-table jsou objednavky, ktere nese z kuchyne na stoly
waiters-own [served-tables orders-to-kitchen orders-to-table]

;kuchyn
;orders-to-cook jsou prijate objednavky na jidlo (prave se vari=pripravuji)
;orders-cooked jsou hotova jidla k vyzvednuti
kitchens-own [orders-to-cook orders-cooked]

;left-ok je pocet hostu, kteri opustili restauraci vcas, vycerpano <0; 75) % casu na obed
;left-ok je pocet hostu, kteri opustili restauraci ve spechu, vycerpano <75; 90) % casu na obed
;left-unsatisfied je pocet hostu, kteri opustili restauraci nespokojeni, vycerpano <90; 100> % casu na obed
;total-spent-time je celkovy cas vsech hostu, stravenych obedem, pouzivame pro spocitani prumerne straveneho casu na obed
globals [left-ok left-in-rush left-unsatisfied total-visit-time]



to setup
  
  ca ;clear all
  reset-ticks
  
  if layout = "fixed with 20 tables and 1 entrance" [
    setup-fixed
  ]
  
  
  if layout = "random using set tables and entrances" [
    setup-random
  ]
  
  ;spolecny setup pro vsechny layouty
  
  ;cisnici dle nastaveni
  create-waiters waiters-count [
    set color blue;
    set size 1
    setxy random-pxcor random-pycor ;nahodne umisteni hosta, meli by se generovat u dveri
    set served-tables [] ;hoste, o ktere se cisnik stara, nepredavaji si je
    set orders-to-kitchen [] ;objednavky, ktere nosi do kuchyne (objednana jidla)
    set orders-to-table [] ;objednavky, ktere nosi z kuchyne na stul (donesena jidla)
  ]
  
  
  ;kuchyne vzdy 1, uprostred
  create-kitchens 1 [
    set color white;
    set label-color grey;
    set shape "square"
    set size 2
    setxy 0 0 ;kuchyn je uprostred
    set orders-to-cook []; objednavky k uvareni
    set orders-cooked []; objednavky uvarene, muzou se rozdavat
    if show-labels? [
      set label self
    ] 
  ]
  
  
  ask waiters[
    set served-tables [] ;zatim zadne stoly
  ]
  
  
  ;cisnici si rozdeli stoly
  ask tables [
    
    let waiter min-one-of waiters [ length served-tables ] ; vyber cisnika s nejmensim poctem stolu, ktere obsluhuje. Rozdeli to spravedlive, postupne by meli mit vsichni cisnici stejny pocet stolu.
    
    ask waiter [
      set served-tables lput myself served-tables  ;uloz cisnikovi stul, ktery bude obsluhovat.
    ]    
  ]
  
  
  ;pridej na seznam mist, ktere prochazi taky kuchyn
  ask waiters[
    set served-tables lput one-of kitchens served-tables
  ]
  
end


;nastaveni vychozich hodnot pro simulaci
to reset
  
  set layout "fixed with 20 tables and 1 entrance"
  set tables-count 20
  set guest-every-nth-tick 60
  set max-ticks-for-lunch 2700 ;na jidlo max 45 minut, 15 minut potrebuji na prichod/odchod z/do prace
  set waiters-count 2
  set max-ticks-needed-for-preparing-meal 60 ;1 jidlo se max.pripravuje 1 minutu
  set entrances-count 1
  set max-ticks-needed-for-eating 1800 ; na jidlo potrebuje max 30 minut
  setup
  
end


;pevne nastaveni pro 20 stolu a 1 vychod
to setup-fixed
  
  set tables-count 20
  set entrances-count 1
  
  ;rozmisteni stolu dle skutecnosti

  ;ctverec s 15 stoly   
  let x [-10 -7 -10 -7 -10 -7 -10 -7 -10 -7 10 7 10 7 10 7 10 7 10 7]
  let y [6 6 3 3 0 0 -3 -3 -6 -6 6 6 3 3 0 0 -3 -3 -6 -6]  
    
    (foreach x y [
      
      create-tables 1 [
        set color brown
        set places table-seats
        set size 2
        set free-places 4 ;pri kroku se prepocitava
        set shape "square"
        setxy ?1 ?2
        set orders []
        set meals []
        if show-labels? [
          set label self
        ]
      ]
    ])
    
    ;1 vchod/vychod
    create-entrances 1 [
      set color red;
      set shape "square"
      set size 2
      setxy 0 -15
      if show-labels? [
        set label self
      ]
    ]
    
end


;nahodne rozmisteni stolu a vychodu
to setup-random
  
  ca ;clear all
  reset-ticks
  
  ;stoly jsou umisteny nahodne
  create-tables tables-count [
    set color brown
    set places table-seats
    set size 2
    set free-places 4 ;pri kroku se prepocitava
    set shape "square"
    setxy random-pxcor random-pycor ;nahodne umisteni stolu, jeste predelame, aby byly vic pohromade
    set orders []
    set meals []
    if show-labels? [
      set label self
    ]
  ]
    
    
  ;vchody/vychody nahodne
  create-entrances entrances-count [
    set color red;
    set shape "square"
    set size 2
    setxy random-pxcor random-pycor
    if show-labels? [
      set label self
    ]
  ]
    
end


;spusteni simulace
to go
  
  if ticks >= max-ticks [stop]; stop, pokud jsme dosahli limitu behu simulace
  
  ask tables[
    update-free-places ;aktualizuj info o volnych stolech
  ]
  
  
  if (ticks mod guest-every-nth-tick) = 0 [
    create-guests 1 [ ;TODO hosti chodi ve skupinkach
      set color white ;hladovi hosti jsou bili
      set size 1
      ;set shape "person"
      
      let entrance one-of entrances ; vchod/vychod, ve kterem se objevi host
      
      setxy [xcor] of entrance [ycor] of entrance ;host se objevi v nejakem exitu
      set choosed-table ""
      set state "coming" ;host zrovna prichazi
      set choosed-exit "" ;jeste nema vybrany vychod, rozhoduje se az pri odchazeni
    ]
  ]
  
    
    
  ask guests[
    ;prijd do restaurace
    guest-seat ;zaber stul
    guest-order
    guest-grab-meal
    guest-eat
    guest-leave
    ;order ;objednavej jidlo
    ;eat ; jez
    ;pay ; plat
    ;leave ;odejdi
    guest-update-time ;aktualizuj cas, ktery ma na obed

    if show-labels? [
      guest-update-label
    ]
    ;
    
  ]
  
  
  ask waiters[
    waiter-circle-between-kitchens-and-tables
    waiter-skip-empty-tables
    waiter-pick-up-orders ;vyzvedni objednavky od stolu
    waiter-push-orders ;dej objednavky do kuchyne
    waiter-pull-orders ;vyzvedni hotove objednavky z kuchyne
    waiter-put-orders ;dej jidlo na stul
    waiter-collect-money
    
    if show-labels? [
      waiter-update-label
    ]
    ]
  
  
  ask kitchens[
    kitchen-cook
    ]
  
    
  tick
  
  
end


;cisnici pendluji mezi stolama a kuchyni
to waiter-circle-between-kitchens-and-tables
  
  if length served-tables = 0 [stop] ;nema stoly, nema praci, nechodi. Nastane, pokud je cisniku vic nez stolu.
  if not waiter-got-any-guests? [stop] ;nema hosty, nic nedela
  if not waiter-got-work? [ stop ] ;nema zadnou praci, nic nedela
    
  ;bez k prvnimu stolu na seznamu
 
  let table first served-tables ;prvni stul na seznamu
  
  ifelse (at-table? and one-of tables-here = table) or (at-kitchen? and one-of kitchens-here = table)[ ;jsem u stolu nebo v kuchyni, ke kteremu jsem smeroval, rotuj dalsi cil
    ;jakmile jsi u stolu, dej tento stul na konec seznamu a pokracuj k dalsimu prvnimu stolu
    ;rotuj seznam
    set served-tables but-first served-tables ;vynech prvni stul, posun seznam, takze druhy stul bude prvni
    set served-tables lput table served-tables ;a prvni stul dej na konec
  ][
  ;nejsi u stolu, jdi k nemu
  facexy [xcor] of table [ycor] of table ;nasmeruj se
  fd 1 ;jdi o 1 policko
  ]
  
end

;cisnik
;preskoc prazdne stoly
to waiter-skip-empty-tables
  
  let table first served-tables ;prvni stul/kuchyn na seznamu
  
  let waiter self ;cisnik do promenne, zjednoduseni pro pouziti v iteraci
     
    let skip false ;zatim nepreskakujeme
    
    if [breed] of table = tables [ ;stoly
      ask table[        
        set skip count guests-here = 0 ;stoly preskakujeme, pokud u vysledneho stolu neni zadny host
      ]
    ]
    
    if [breed] of table = kitchens [ ;kuchyne
        set skip (length [orders-to-kitchen] of self = 0) and (length [orders-cooked] of table = 0);kuchyni preskakujeme, pokud cisnik nema objednavky k predani a kuchyn nema nic pripraveno k vydani
    ]
    
    
    if skip = true [
      set served-tables but-first served-tables ;vynech prvni stul, posun seznam, takze druhy stul bude prvni
      set served-tables lput table served-tables ;a prvni stul dej na konec
    ]
  
end


;cisnik
;predej objednavky do kuchyne
to waiter-push-orders
  
  if not at-kitchen? or empty? orders-to-kitchen [ stop ] ;pokud neni v kuchyni, nebo nema co objednat, nepokracujeme
  
  ask one-of kitchens-here [ ;dej do kuchyne
    
    foreach [orders-to-kitchen] of myself [ ;projdi vsechny cisnikovy objednavky
      set orders-to-cook lput ?1 orders-to-cook ;a kazdou z nich postupne po 1 dej na konec fronty objednavek
    ]
    
  ]
  
  set orders-to-kitchen [] ;predal vsechny objednavky, zadny nema
    
end



;cisnik
;vyzvedni jen MOJE objednavky z kuchyne

to waiter-pull-orders
  
  if not at-kitchen? [ stop ] ;pokud neni v kuchyni, nepokracujeme
   
  ask one-of kitchens-here [ ;vyzvedni z kuchyne
    
    foreach orders-cooked [ ;projdi vsechna jidla pripravena k vydani 
      
      if member? ?1 [served-tables] of myself [;je to objednavka pro stul, ktery obsluhuju? myself=cisnik
        ask myself[ ;cisnik
          set orders-to-table lput ?1 orders-to-table ;seznam objednavek k rozneseni u cisnika (orders-to-table) je prazdny, lep rovnou na konec
        ]             
      ]
    ]
  ]
  
   ;cisnik 
   ask self [
     ;projdi vsechny jeho stoly a zrus objednavky k jeho stolum, prave si je vyzvedl
     foreach served-tables [
       ask one-of kitchens-here [
         set orders-cooked remove ?1 orders-cooked
       ]
     ]
   ]
  
end



;cisnik
;vyzvedni objednavky od stolu
to waiter-pick-up-orders
  
  if not at-table? [ stop ] ;pokud neni u stolu, nema co vyzvedavat
  
  ;nekontroluju, zda vyzvedava objednavku, ktera patri ke stolu, ktery obsluhuje. Proste kdyz ke stolu prisel, ocekavam, ze ho obsluhuje.
  ;vyzvedne vsechny objednavky najednou
   
  ask one-of tables-here[ ;stul u ktereho je cisnik
    
    foreach orders [ ;postupne kazdou objednavku ze stolu
      
      ask myself [ ;cisnik
        set orders-to-kitchen lput ?1 orders-to-kitchen ;presun do objednavek cisnika
      ]
      
    ]
    
    set orders [] ;zrus objednavky na stul, uz je ma vsechny cisnik
    
  ]
  
  
end


;cisnik
;poloz objednavky na stul
to waiter-put-orders
  
  if not at-table? or empty? [orders-to-table] of self [ stop ] ;pokud neni u stolu nebo nema co polozit, koncime
  
  ask self [ ;cisnik
    
    foreach orders-to-table [ ;cisnikovy jidla v ruce
      
      ask one-of tables-here [ ;stul
        if self = ?1[ ;patri jidlo na tento stul?
          set meals lput ?1 meals ;poloz 1 jidlo na stul
        ]
      ]
      
    ]
    
    ;zrus vsechna jidla cisnika k tomuto stolu, uz je rozdal
    set orders-to-table remove (one-of tables-here) orders-to-table ;objednavka je "stul", takze zrus "stoly" ke stolu
    
  ]  
  
end


;cisnik
;kasiruj
to waiter-collect-money
  
  if not at-table? [ stop ] ;pokud neni u stolu nebo nema co polozit, koncime
  
  ask guests-here with [state = "wanna pay"] [
    set state "leaving"
  ]
    
end


;host
;aktualizuj barvu "nastvanosti"
to guest-update-time
  
  set time time + 1
  let ratio (time / max-ticks-for-lunch) * 100
  
  if ratio <= 75 [ set color green ] ;OK
  if ratio > 75 and ratio <= 90 [ set color orange ]
  if ratio > 90 [set color red] ;nastvani, nestihaji
  
end


;cisnik
;dej do popisky objednana jidla
to waiter-update-label
  ifelse length orders-to-kitchen > 0 [
    set label orders-to-kitchen
  ] [
  set label ""
  ]
end


to guest-update-label
  set label state ;item state guest-states
  set label-color color
end


; nahodny pohyb o 1 policko
to move
  rt random 50
  lt random 50
  fd 1
end


;stul
;aktulizuj pocet volnych mist
to update-free-places
   set free-places places - count guests-here 
   ;set label free-places
end


;host
;najdi prazdy stul a jdi k nemu
;posad se
to guest-seat
  
  if (not at-table?) and state = "coming" [set state "seating"]
  
  if not (state = "seating" ) [stop] ;pokud se nemam posadit, preskakuju
  
  ;nema zatim vyhlidnuty stul, najdi ho
  ;pripadne ma stul vybrany, ale je obsazeny, musis najit novy
  ifelse choosed-table = "" or (choosed-table != "" and [free-places] of choosed-table < 1)[
       
    let table (max-one-of (tables with [free-places > 0 ]) [free-places])  ; vyber nejblizsi stul s nejakym volnym mistem
    
    ;let table one-of (tables with [free-places > 0 ])  ; vyber nejaky stul s nejakym volnym mistem
    
    ifelse table != nobody [ ;stul existuje
      facexy [xcor] of table [ycor] of table ;nasmeruj se ke stolu
      set choosed-table table ;uloz stul, ktery jsem vybral
      fd 1 ;jdi ke stolu
    ] [
    ;neni volny stul, co mam delat?
    ;ted stuj
    ]
    
  ] [
  
  ;mam stul a je porad volny, jdu k nemu
  facexy [xcor] of choosed-table [ycor] of choosed-table 
  fd 1;jdi ke stolu
  ]  
  
  ;stul si aktualizuje stav, co kdyby se prave usadil?
  if choosed-table != ""[
    ask choosed-table[
      update-free-places
    ]
  ]
  
end


;objednavka
;musi byt posazeny u sveho stolu
;musi u nej byt cisnik
to guest-order
  
  if at-table? and state = "seating" and one-of tables-here = choosed-table [ set state "ordering" ] ;ordering
  
  if not (state = "ordering" and waiter-here?) [stop] ;jidlo objednavam, jen pokud chci prave objednavat a u stolu je cisnik
  
  ;cisnik je tady, objednavam
 
  ;objednavky jsou na "na stul" ne na "hlavu", cisnici takhle pracuji
  ;objednavka je ted objekt stolu, nebereme v potaz jidlo, pro flow to ted neni dulezite
  ;aka "na tento stul objednavam gulas"
  ask one-of tables-here[
    set orders lput self orders
    ]

  set state "waiting" ;ceka na jidlo  
  
  ;objednavam
  ;output-print self
  ;output-print "objednavam"
  
end


;host
;vezmi si jidlo
to guest-grab-meal
  
  if not (state = "waiting") [ stop ] ;pokud neceka na jidlo, nepokracuj
  
  ask one-of tables-here [ ;stul
    
    if not empty? meals [ ;je nejake volne jidlo na stole?
      
      let m first meals ;prvni volne jidlo
      ;TODO jidlo si muzes vzit, jenom pokud budes cekat nejdele, jinak se muze stat, ze zacnes jist jidlo, ktere objednal host pred tebou
      
      ;vezmi si ho
      ask myself[ ;host
        set meal m ;tohle jidlo mam ja
        set state "eating"
      ]
      
      set meals but-first meals ;stul, zmizi jedno volne jidlo, vzal si ho prave host
      
    ]
    
  ]
  
end


;host
;jez jidlo
to guest-eat
  
  if not (state = "eating") [ stop ] ;pokud neji, nepokracuj
  
  if ticks mod max-ticks-needed-for-eating = 0 [
    set meal ""
    set state "wanna pay"
    ]
  
end


;host
;odejdi
to guest-leave
   
  if not (state = "leaving") [ stop ] ;pokud nema odejit, neodchazej

  ;pokud nema vybrany vychod, vyber jej
  if choosed-exit = "" [
    set choosed-exit min-one-of entrances [distance myself] ;zvol nejblizsi vychod
    ]

  ifelse at-entrance? [
    
    ;aktualizuj statistiky hostu
    if color = green [set left-ok left-ok + 1]
    if color = orange [set left-in-rush left-in-rush + 1]
    if color = red [set left-unsatisfied left-unsatisfied + 1]
    
    set total-visit-time total-visit-time + time
    
    die

    ]
  [ 
    ;neni u vychodu, jdi k nemu
    facexy [xcor] of choosed-exit [ycor] of choosed-exit
    fd 1;jdi k vychodu
  ]
  
end


;kuchyn
;uvar jidlo
to kitchen-cook
  
  if empty? orders-to-cook [ stop ] ;kdyz nic nemam varit, tak nevarim

  ;pripravi jidlo k vydani
  ;TODO lze dat brzdu, treba poisson, apod.
  ;predpokladam, ze je to restaurace v dobe obeda, takze se nevari, ale jen vydavaji obedy (menu), ktere uz jsou uvarene
  if ticks mod max-ticks-needed-for-preparing-meal = 0 [ ;pokud jsem dosahl limitu na vydej
    set orders-cooked lput first orders-to-cook orders-cooked ;vem prvni jidlo z fronty a dej ho na konec jidel k vydani
    set orders-to-cook but-first orders-to-cook ;z fronty jidel k priprave zrus prvni polozku, uz je pripraveno k vydani
  ]

end



;jsem u stolu?
to-report at-table?
  report count tables-here > 0
end


;jsem v kuchyni?
to-report at-kitchen?
  report count kitchens-here > 0
end

;jsem u vchodu/vychodu?
to-report at-entrance?
  report count entrances-here > 0
end


;cisnik
;ma praci? tzn je u nejakeho stolu host / ma neco pro kuchyni / ma neco odnes z kuchyne na stul? pokud ano, ma praci
to-report waiter-got-work?
  
  let got-work false
   
  set got-work waiter-got-guests-to-serve? ;ma hosty = ma praci
  
  foreach served-tables[ ; projdi kuchyne
    
    if got-work != true [ ;kontroluj, jen pokud se nenajde prvni "prace"
      
      if [breed] of ?1 = kitchens [ ;kuchyne
        set got-work (length [orders-to-kitchen] of self > 0) or (length [orders-cooked] of ?1 > 0);ma neco pro kuchyni nebo v kuchyni je navareno k vydani = ma praci (ale jen kdyz ma hosty, jinak se bude jen motat dle objednavek ostatnich)
      ]
    ]
  ]
  
  report got-work
  
end


;cisnik
;ma hosty, ktere muze obsluhovat?
to-report waiter-got-guests-to-serve?
  
  let got-work false
  
  let waiter self
  
  foreach served-tables[
    
    if got-work != true [ ;kontroluj, jen pokud se nenajde prvni "prace"
      
      if [breed] of ?1 = tables [ ;stoly
        ask ?1 [
          foreach sort guests-here[
            if got-work != true [
              ;ma hosta, pokud je to host, ktery chce objednat / zaplatit / chce jidlo a ja mam v ruce jidlo
              set got-work ([state] of ?1 = "ordering" or [state] of ?1 = "wanna pay" or ( [state] of ?1 = "waiting" and length [orders-to-table] of waiter > 0))
            ]
          ]
        ]
      ]
    ]
  ]
  
  report got-work
  
end



;cisnik
;ma nejaky hosty?
;tzn ma stul, u ktereho nekdo sedi?
to-report waiter-got-any-guests?
  
  let got-work false
  
  let waiter self
  
  foreach served-tables[
    
    if got-work != true [ ;kontroluj, jen pokud se nenajde prvni "prace"
      
      if [breed] of ?1 = tables [ ;stoly
        ask ?1 [
          if got-work = false [
            set got-work length sort guests-here > 0
          ]
        ]
      ]
    ]
  ]
  
  report got-work
  
end


;host
;je u me nejaky cisnik?
to-report waiter-here?
  report any? waiters-here
end
@#$#@#$#@
GRAPHICS-WINDOW
669
29
1238
489
21
16
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
-21
21
-16
16
0
0
1
ticks
30.0

SLIDER
376
48
548
81
tables-count
tables-count
1
100
20
1
1
NIL
HORIZONTAL

BUTTON
146
320
209
353
go
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

BUTTON
220
320
301
353
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
255
96
427
129
waiters-count
waiters-count
1
100
2
1
1
NIL
HORIZONTAL

SLIDER
378
149
560
182
max-ticks-for-lunch
max-ticks-for-lunch
1
3600
2700
1
1
NIL
HORIZONTAL

SLIDER
436
96
608
129
table-seats
table-seats
1
6
4
1
1
NIL
HORIZONTAL

PLOT
72
362
526
579
guest's satisfaction when left
time (ticks)
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"% ok" 1.0 0 -10899396 true "" "if left-ok + left-in-rush + left-unsatisfied > 0 [\nplot left-ok / (left-ok + left-in-rush + left-unsatisfied)  * 100\n]"
"% in rush" 1.0 0 -955883 true "" "if left-ok + left-in-rush + left-unsatisfied > 0 [\nplot left-in-rush / (left-ok + left-in-rush + left-unsatisfied)  * 100\n]"
"% unsatisfied" 1.0 0 -2674135 true "" "if left-ok + left-in-rush + left-unsatisfied > 0 [\nplot left-unsatisfied / (left-ok + left-in-rush + left-unsatisfied)  * 100\n]"

SLIDER
73
148
369
181
max-ticks-needed-for-preparing-meal
max-ticks-needed-for-preparing-meal
1
900
60
1
1
NIL
HORIZONTAL

SLIDER
74
197
312
230
max-ticks-needed-for-eating
max-ticks-needed-for-eating
1
3600
1800
1
1
NIL
HORIZONTAL

MONITOR
213
661
280
706
ordering
count guests with [state = \"ordering\"]
17
1
11

MONITOR
431
662
502
707
wanna pay
count guests with [state = \"wanna pay\"]
17
1
11

MONITOR
516
661
573
706
leaving
count guests with [state = \"leaving\"]
17
1
11

MONITOR
142
662
200
707
seating
count guests with [state = \"seating\"]
17
1
11

MONITOR
293
662
343
707
waiting
count guests with [state = \"waiting\"]
17
1
11

MONITOR
482
600
623
645
kitchen orders-to-cook
length [orders-to-cook] of one-of kitchens
17
1
11

SLIDER
73
96
245
129
entrances-count
entrances-count
1
5
1
1
1
NIL
HORIZONTAL

MONITOR
634
600
789
645
kitchen orders-cooked
length [orders-cooked] of one-of kitchens
17
1
11

MONITOR
72
660
129
705
coming
count guests with [state = \"coming\"]
17
1
11

MONITOR
587
661
644
706
left
left-ok + left-in-rush + left-unsatisfied
17
1
11

MONITOR
361
662
415
707
eating
count guests with [state = \"eating\"]
17
1
11

MONITOR
541
418
598
463
NIL
left-ok
17
1
11

MONITOR
541
474
628
519
NIL
left-in-rush
17
1
11

MONITOR
540
534
648
579
NIL
left-unsatisfied
17
1
11

SWITCH
241
273
379
306
show-labels?
show-labels?
0
1
-1000

MONITOR
541
362
630
407
guests-here
count guests
17
1
11

MONITOR
262
599
355
644
% unsatisfied
precision (left-unsatisfied / (left-ok + left-in-rush + left-unsatisfied) * 100) 2
17
1
11

MONITOR
151
599
249
644
% left-in-rush
precision (left-in-rush / (left-ok + left-in-rush + left-unsatisfied) * 100) 2
17
1
11

MONITOR
72
598
138
643
% left-ok
precision (left-ok / (left-ok + left-in-rush + left-unsatisfied) * 100) 2
17
1
11

SLIDER
324
198
496
231
max-ticks
max-ticks
100
1000000
1000000
1
1
NIL
HORIZONTAL

BUTTON
73
319
136
352
setup
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

INPUTBOX
73
247
228
307
guest-every-nth-tick
60
1
0
Number

MONITOR
373
600
467
645
avg visit time
round (total-visit-time / (left-ok + left-in-rush + left-unsatisfied))
17
1
11

CHOOSER
73
38
361
83
layout
layout
"fixed with 20 tables and 1 entrance" "random using set tables and entrances"
0

BUTTON
311
320
478
353
reset to default values
reset
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

This model simulates general traffic flow in a restaurant during lunch time. 

During these hours, guests come, seat and wait for a waiter. When the waiter come they make an order from menu. Waiter goes to kitchen with the order and kitchen (cook) prepares ordered lunch. Then waiter pull-up the lunch (lunches) and bring it back to the guest's table.
After lunch the guest wants to pay. He waits for the waiter, pays and leaves the restaurant.

Each guest has limited time for his lunch only. When they exceed 90% of the maximum time they get angry and unsatisfied and propably won't come again.

Our task is to keep the rate of unsatisfied guests as low as possible. Also, we would like to keep the number of waiters at minimum as well due to economical reasons.


## HOW IT WORKS

### Static (non-moving) objects:

#### Kitchen

* white square shape
* there is always one kitchen in the simulation and its position is always in the middle of the world.
* kitchen receives orders from waiters and prepares meals. The „speed“ of the preparation can be set by _**max-ticks-needed-for-preparing-meal**_. Using this value, one meal is prepared every n-th tick.
* kitchen has two queues: _**orders-to-cook**_ (queue to be done) and _**orders-cooked**_ (finished queue). _**Orders-to-cook**_ is filled by waiters (they empty their _**orders-to-kitchen**_ here) and _**orders-cooked**_ is filled by the kitchen itself.
* If we want to scale up the kitchen to be as fast as possible we need to set up the _**max-ticks-needed-for-preparing-meal**_ slider to the smallest value (1). Then every tick one meal can be prepared.

#### Tables

* brown square shape
* tables are served by waiters
* number of tables can be set by _**tables-count**_ slider
* tables are positioned randomly except the case when _**fixed with 20 tables and 1 entrance**_ layout is used. In this case, fixed layout and only 20 tables are set.


#### Entrances / Exits

* red square shape
* number of entrances can be set through _**entrances-count**_ slider
* guests come and leave througt entrances / exits
* coming through particular entrance is random
* when guests leave they're looking for the nearest entrance from the table which they just left.
* entrances and exists are positioned randomly except the case when _**fixed with 20 tables and 1 entrance**_ layout is used. In this case, fixed layout and only 1 entrance is set.

#### Layouts

* a layout is a positioning of tables and entrances for simulation use-cases
2 layouts (via chooser) can be set:
    * fixed with 20 tables and 1 entrance – this layout is just for purposes of „Simulation of Systems, 4IT496“ Course at University of Economics, Prague.
    * random using set tables and entrances – this layout puts the tables and entrance randomly in the world

### Dynamic (moving) objects:

#### Guests

* Green / orange / red arrow shape (set by time remaining, see bottom)
* One guest comes every n-th tick set by _**guest-every-nth-tick**_ input
* A maximum time for the lunch is 60 minutes.
* When guests spend (0; 75> % of the maximum time in the restaurant they're OK and they're green
* When they spend (75; 90> % they're in rush, orange.
* When they spend (90; 100> % they are unsatisfied because they won't be back at their work on time, red.
* A guest's flow is following: 
    * coming – the very first state when guests come to the restaurant
    * seating – they're looking for a free place at any table but they prefer to sit alone
    * ordering – when they get a seat they're waiting for their waiter (every waiter has his table where he's serving to)
    * waiting – whey they put an order to the waiter they're waiting for ordered meal
    * eating – when the waiter brings the meal they're eating
    * wanna pay – when they're finished with the meal they're waiting for the waiter again as they want to pay
    * leaving – done with pay, they're looking for the nearest exit and leaving the restaurant
    * left – the last and „fake“ state, just for statistical reasons. Guests in this state doesn't exist anymore but we need to know how many guests visited our restaurant since we opened.


#### Waiters

* blue arrow shape
* waiters serve to guests through tables
* at the setup phase, every waiter will draw the tables where they're serving at. The drawing process is random and „fair“ as every waiter has almost same number of tables. For example if we have 4 tables and 2 waiters, each of them has 2 tables. If we have 5 tables and 2 waiters, first waiter will have 2 tables and the second one has 3 tables because 1 table can be served just by 1 waiter, not more.
* If the number of waiters is greater than number of tables, the remaining waiters don't serve and they're stucked and useless.
* Waiters circulate between tables and kitchen.
* They skip empty tables.
* They skip kitchen if there is nothing to put or pick up from it.
* When they receive an order from a customer they put it to the _**orders-to-kitchen**_ queue and this queue is passed to the kitchen on the next visit.
* Whey they pick up finished meal from the kitchen they put the meal to the _**orders-to-table**_ queue and the meal (order) is served to the table where it belongs to.
* The number of waiters can be set via _**waiters-count**_ slider.
* The optimum is to have as many waiters as tables but in reality it's not possible.

## HOW TO USE IT

### Quick Start

Default values are OK to run. So just press _**reset to default values**_ button and then "go". Then watch the amazing simulation.

### Interface description

#### Choosers

* layout – table and entrance positioning, see above „layout“

#### Sliders and Choosers

* tables-count – number of tables used in the simulation. This variable will take into account only if we use „random using set tables and entrances“ layout. Default is 20.
* entrances-count – number of entrances/exits. This variable will take into account only if we use „random using set tables and entrances“ layout. Default is 1.
* waiters-count – number of waiters. Typical value is 2-5 waiters for one restaurant. Default is 2.
* table-seats – number of seats at one table. More seats we have, more guest we can serve. Default is 4 so 1 table can hosts 4 guests.
* max-ticks-needed-for-preparing-meal - time for preparing one meal in the kitchen. Default is 60 (60 ticks=60 seconds). It uses modulo: When _**ticks mod max-ticks-needed-for-preparing-meal = 0**_, one meal (lunch) is prepared for pull out by a waiter for particular table.
* max-ticks-for-lunch - guest's time for lunch. Default is 2700 ticks which stands for 2700 seconds (45 minutes).
* max-ticks-needed-for-eating - time for eating lunch. Default is 1800 which stands for 1800 seconds (30 minutes). It uses modulo: When ticks mod _**max-ticks-needed-for-eating = 0**_, a guest is done with his lunch. 
* max-ticks - maximum ticks when the simulation will stop. Just for convenience, doesn’t have any impact to the model but we need to stop running simulation at the same time for make an analysis.

#### Inputs 
* guest-every-nth-tick - every n-th tick a new guest will come. Default is 60 so 1 guest will come each minute. Recommended value is between 20-100. 

#### Switches

* show-labels? - would we like to see guests states and orders on the fly? Default on.


#### Buttons

* setup – this button set up the simulation, place objects and make drawing of waiters for their tables.
* go – run the simulation up to „max-ticks“ variable, then stops.
* go once – run one step of simulation.
* reset to default values – set up the simulation for 4IT496 purposes (a local restaurant problem). Simulation conclusion will follow values set up by this button.

#### Plots
* guest's satisfaction when left – this plot will show % graph of guests mood. Green – they left restaurant on time, Orange – they're in rush (time is almost gone) and Red – they exceeded the time dedicated to their lunch.


#### Monitors
* guests-here - number of guests in restaurant now 
* left-ok - number of guests who left the restaurant with good feeling (time for lunch hasn’t been exceeded) 
* left-in-rush - number of guests who left the restaurant in rush (time for lunch has been almost exceeded) 
* left-unsatisfied - number of guests who left the restaurant unsatisfied (time for lunch has been exceeded) 
* % left-ok - rate of guests who left the restaurant with good mood (time for lunch hasn’t been exceeded) related to total guests 
* % left-in-rush - rate of guests who left the restaurant in rush (time for lunch has been almost exceeded) related to total guests 
* % left-unsatisfied - rate of guests who left the restaurant unsatisfied (time for lunch has been exceeded) related to total guests 
* avg visit time – how many secods (ticks) guests spent in restaurant in average. The lower is the better.
* coming, seating, ordering, waiting, eating, wanna-pay, leaving, left - number of guests with these states 
* kitchen orders-to-cook - number of orders in kitchen waiting to be cooked 
* kitchen orders-cooked - number of orders in kitchen waiting to be pull-out by its waiter 

#### Choosers

* guest-every-nth-tick - every n-th tick a new guest will come. Default is 50. Recommended value is between 20-100.

#### Monitors
* guests-here - number of guests in restaurant now
* left-ok - number of guests who left the restaurant with good feeling (time for lunch hasn't been exceeded)
* left-in-rush - number of guests who left the restaurant in rush (time for lunch has been almost exceeded)
* left-unsatisfied - number of guests who left the restaurant unsatisfied (time for lunch has been exceeded)
* % left-ok - rate of guests who left the restaurant with good feeling (time for lunch hasn't been exceeded) related to total guests
* % left-in-rush - rate of guests who left the restaurant in rush (time for lunch has been almost exceeded) related to total guests
* % left-unsatisfied - rate of guests who left the restaurant unsatisfied (time for lunch has been exceeded) related to total guests
* coming, seating, ordering, waiting, eating, wanna-pay, leaving, left - number of guests with these states
* kitchen orders-to-cook - number of orders in kitchen waiting to be cooked
* kitchen orders-cooked - number of orders in kitchen waiting to be pull-out by its waiter

#### Plots

* guest's satisfaction when left - graphical representation of guest's feeling

#### Buttons

* setup - set up a new simulation
* go once - one step in the simulation
* go - run the simulation

## THINGS TO NOTICE

* due to random placing of the tables, the best thing is to have kitchen in the middle of the space
* every move is expensive
* distance matters. In the case the tables are near to each other the efficiency is much better
* best thing is to have one waiter for each table. But it's not as the reality works
* small space = better efficiency
* number of seats at a table is not as important because waiter has to come regardless of 1 or 10 guests

## THINGS TO TRY

* set guest-every-nth-tick to 1, tables-count to 20, waiters-count to 5 and speed-up the simulation. A flock will arise :).

## EXTENDING THE MODEL

* the tables shouldn't be placed randomly because distance matters. In every restaurant, tables placing is different so the simulation should be set up for particular restaurant
* more kitchens
* pricing
* rate of unsatisfied guest influences number of new guests
* guests and waiters avoiding
* guest will come on the basis of a statistical function (poisson distribution, for example)

## NETLOGO FEATURES

-

## RELATED MODELS

-

## CREDITS AND REFERENCES

Author: Bc. Jiří Hradil (jiri@hradil.cz)
Created for: The University of Economics, Prague
First release: 18.12.2012

<a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/cz/deed.en_US"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc/3.0/cz/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/cz/deed.en_US">Creative Commons Attribution-NonCommercial 3.0 Czech Republic License</a>.
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
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
