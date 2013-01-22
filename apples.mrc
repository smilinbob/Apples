;   Apples Script by Mike (Smilinbob) Caffray.
;   Copyright (C) 2013 Michael Caffray
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;
on *:LOAD: {
  dialog -m appcfg appcfg
  if (!$shufftok(1,32)) {
    load -rs apples\shufftok.mrc
  }
}
on *:JOIN:#: {
  if ($chan == $appchan) {
    if ($aget($nick) > 0) {
      mode $appchan +v $nick
    }
  }
}
on *:START: {
  var %sn = 1
  while (%sn <= $ini(apples\appcfg.ini,0)) {
    if ($appop($ini(apples\appcfg.ini,%sn),aconn)) {
      server -m $ini(apples\appcfg.ini,%sn)
    }
    inc %sn
  }
}
on *:CONNECT: {
  if ($appop($network,aconn)) {
    join $appop($network,chan)
    checkchan
  }
  if ($appop($network,extcrd)) {
    if (!$isdir(apples\ $+ $network)) {
      mkdir apples\ $+ $network
    }
    if (!$isfile(apples\ $+ $network $+ \ $+ red.txt)) {
      write apples\ $+ $network $+ \ $+ red.txt
    }
    if (!$isfile(apples\ $+ $network $+ \ $+ green.txt)) {
      write apples\ $+ $network $+ \ $+ green.txt
    }
  }
}
on *:TEXT:.apples*:#: {
  if (# != $appchan) {
    msg # Please go to $appchan to play Apples to Apples.
  }
}
on *:TEXT:*:#: {
  if (# == $appchan) {
    if ($chr(36) isin $1-) {
      halt
    }
    ;---------------------------------------------------------------------------------------------VOTE
    if ($aget(phase) == vote) {
      if (($nick == $applayer($aget(judge))) || ($aget(mode) == allvote)) {
        if (!$2-) {
          if ($int($1) isnum 1- $numtok($aget(subs),131)) {
            if ($nick == $gettok($aget(subs),$1,131)) {
              if ($aget(mode) ==  allvote) {
                msg $nick You cannot vote for your own card
              }
              else {
                .msg $appchan $nick $+ , You cannot vote for your own card.
              }
            }
            else {
              vote $int($1) $nick c
            }
          }
        }
      }
    }    
    ;---------------------------------------------------------------------------------------------.APPLES
    if ($1 == .apples) {
      if ($aget(phase)) {
        msg $appchan there is already a game in progress.
      }
      else {
        hmake $aname
        alog Initiated
        if ($2-) {
          var %mods = $2-
          var %nn = 1
          while (%nn <= $numtok(%mods,32)) {
            if ($gettok(%mods,%nn,32) isnum ) {
              var %num = $int($V1)
            }
            inc %nn
          }
          if (double isin $2-) {
            hadd $aname mode double
          }
          elseif (allvote isin $2-) {
            hadd $aname mode allvote
          }
          if (round isin %mods) {
            if (!%num) {
              msg $appchan Please specify a number of rounds.
              halt
            }
            else {
              hadd $aname rounds %num
            }
          }
          if (%num) {
            if ($aget(mode) == allvote) {
              if (%num isnum 10-100) {
                hadd $aname wins %num
              }
              else {
                msg $appchan Invalid score. Please choose a score between 10 and 100.
                hfree $aname
                halt
              }
            }
            else {
              if (%num isnum 1-25) {
                hadd $aname wins %num
              }
              else {
                msg $appchan Invalid score. Please choose a score between 1 and 25.
                hfree $aname
                halt
              }
            }
          }
          else {
            if ($aget(mode) == allvote) {
              hadd $aname wins 25
            }
            else {
              hadd $aname wins 5
            }
          }
        }
        else {
          hadd $aname wins 5
        }
        hadd $aname server $server
        notice $appchan A new game is about to start!
        appstart
        notify
        appjoin $nick
      }
    }
  }
  ;---------------------------------------------------------------------------------------------.JOIN
  elseif ($1 == .join) || ($1 == .jion) {
    if ($aget) {
      appjoin $nick
      else {
        msg $appchan There is no game in progress.
      }
    }
  }
  ;---------------------------------------------------------------------------------------------.FJOIN
  elseif ($1 == .fjoin) {
    if ($aget) {
      if ($isappmod($nick)) {
        appjoin $2
      }
      else {
        msg # $nick $+ , you must be a Game Mod to use that command.
      }
    }
    else {
      msg $appchan There is no game in progress.
    }  
  }
  ;---------------------------------------------------------------------------------------------fstart
  elseif ($1 == .fstart) {
    if ($aget(phase) == join) {
      if ($applayer() > 2) {
        .timer $+ $network $+ app20 off
        .timer $+ $network $+ app21 off
        firstround
      }
      else {
        msg $appchan Not enough players to force start.
      }
    }
  }
  ;---------------------------------------------------------------------------------------------ADDCARD
  elseif ($1 == .addcard) || ($1 == .add) { 
    if ($appop($network,extcrd)) {
      if ($appop($network,modadd)) {
        if (!$isappmod($nick)) {
          .msg $appchan Sorry, you need to be a Game Mod to do that.
        }
        else {
          goto Addcard
        }
      }
      else {
        :Addcard
        var %c = $left($2,1)
        if (%c == r) || (%c == g) {
          var %w = $strip($$3-)
          if (!$isclean($3-)) {
            msg # ERROR: The card you tried to add contains illegal characters.
            halt
          }
          if (%c == r) {
            var %col = red
          }
          else {
            var %col = green
          } 
          if (!$cc(%c,%w)) {
            write apples\ $+ $network $+ \ $+ %col $+ .txt %w
            .msg $chan $iif(%c == r,4",3") $+ %w $+ " card added.
            alog $nick added the $iif(%c == r,4",3") $+ %w $+ " card. 
          }
          else {
            .msg $appchan I already have the $iif(%c == r,4",3") $+ %w $+ " card.
          }
        }
        else {
          .msg $appchan invalid color.
        }
      }
    }
    else {
      .msg $appchan Adding cards had been dissabled.
    }
  }
  ;------------------------------------------------------------------------------------------------REMCARD
  elseif ($1 == .remcard) || ($1 == .rem) || ($1 == .remove) {
    if ($2 isin g,greed,red,r) {
      var %c = $left($$2,1)
      var %c2 = $iif(%c == r, red, green)
      if ($read(apples\ $+ $network $+ \ $+ %c2 $+ .txt,w,$$3-)) {
        var %w = $v1
        write -dl $+ $readn apples\ $+ $network $+ \ $+ %c2 $+ .txt 
        .msg $appchan $iif(%c == r,4",3") $+ %w $+ " card removed.
        alog $nick removed the $iif(%c == r,4",3") $+ %w $+ " card.
      }
      elseif ($read(apples\ $+ %c2 $+ .txt,w,$$3-)) {
        var %w = $v1
        .msg $appchan $iif(%c == r,4",3") $+ %w $+ " card cannot be removed because it is in the core set.
      }
      else {
        .msg $appchan I do not have the $iif(%c == r,4",3") $+ $3- $+ " card.
      }
    }
    else {
      msg $chan Invalid color.
    }
  }
  ;------------------------------------------------------------------------------------------------CHECK
  elseif ($1 == .check) { 
    if ($2 == red) || ($2 == r) {
      var %c = 4
    }
    elseif ($2 == g) || ($2 == g) {
      var %c = 3
    }
    else {
      .msg 
    }
    if ($cc($2,$3-)) {
      msg $chan I already have the  $+ %c $+ " $+ $3- $+ " card.
    }
    else {
      .msg $chan I do not have the  $+ %c $+ " $+ $3- $+ " card.
    }
  }
  ;---------------------------------------------------------------------------------------------------WINS
  elseif ($1 == .wins) { 
    if (!$2) {
      if ($readini(apples\score.ini,$network,$nick)) {
        msg $chan $nick $+ , You have won $v1 $iif($v1 > 1,games,game) of apples.
      }
      else {
        msg $chan $nick $+ , you have not yet won any games of apples.
      }
    }
    else {
      if ($readini(apples\score.ini,$network,$2)) {
        msg $chan $2 has won $v1 $iif($v1 > 1,games,game) of apples.
      }
      else {
        msg $chan $2 has not won any games of apples.
      }
    }
  }
  ;---------------------------------------------------------------------------------------------------NOTIFY
  elseif ($1 == .notify) { 
    var %file = apples\ $+ $network $+ \ $+ notify.txt  
    if ($read(%file,w,$nick)) {
      write -dw $nick %file
      notice $nick You will no longer be informed when a game is going to start.
    }
    else {
      write %file $nick
      notice $nick You will now be informed when a game is about to start.
    }
  }
  ;----------------------------------------------------------------------------------------------------APPOFF
  elseif ($1 == .appoff) { 
    if ($hget($aname)) {
      alog Terminated: .appoff command
      appoff
    }
    else {
      .msg # There is no game currently running.
    }
  }
  ;----------------------------------------------------------------------------------------------------STOP
  elseif ($1 == .stop) { 
    if ($aget) {
      if ($isappmod($nick)) { 
        if ($aget(phase) = stop) {     
          msg $appchan Apples is already paused
        }
        else {
          alog Stopped: 2 .stop command
          .msg $appchan Apples is pausing for debugging.
          .timer $+ $network $+ app2? off
          hadd $aname phase stop
        }
      }
      else {
        .msg $appchan You need to be a Game Mod to use that command.
      }
    }
    else {
      msg $appchan There is no game currently running.
    }
  }
  ;----------------------------------------------------------------------------------------------------RESUME
  elseif ($1 == .resume) {
    if ($isappmod($nick)) {
      if ($aget(phase) == stop) {
        if ($applayer() > 2) {
          hdel $aname subs
          redraw
          msg $appchan Resuming game.
          if ($aget(round) > 0) {
            round
          }
          else {
            firstround
          }
        }
        else {
          msg $appchan Not enough players to resume game.
        }
      }
      else {
        msg $appchan There is currently no game paused.
      }
    }
    else {
      msg $appchan You must be a Game Mod to use that command
    }
  }
  ;----------------------------------------------------------------------------------------------------DROP
  elseif ($1 == .drop) { 
    if ($aget) {
      if ($hget($aname,phase) == join) {
        .msg $chan Please wait for the game to start
      }
      else {
        if ($aget(drop)) {
          .msg $appchan i am still waiting for a response from $v1
        }
        elseif ((!$2) || ($2 == $nick) || ($2 == me)) {
          if ($aget($nick)) {
            hadd $aname drop $nick
            drop
          }
        }
        else {
          if ($2 isin $aget(players)) {
            hadd $aname drop $2
            .msg # $2 $+ : You have $duration($aget(dtime)) to say .here, or you will be dropped from the game.
            .timer $+ $network $+ app28 1 $aget(dtime) /drop
          }
          else {
            msg # $2 is not in the game
          }
        }
      }
    }
    else {
      msg $chan No game in progress.
    }
  }
  ;----------------------------------------------------------------------------------------------------QUIT
  elseif ($1 == .quit) {
    if ($aget(phase) != join) {      
      if ($nick isin $aget(players)) {
        if ($aget(drop)) {
          if ($v1 == $nick) {
            .timer $+ $network $+ app28 off
            drop
          }
          else {
            msg $appchan Please wait for a response from $aget(drop)
            halt
          }
        }
        hadd $aname drop $nick
        drop
      }
      else {
        .msg $appchan $nick $+ : you are not in the game.
      }
    }
    else {
      msg $appchan Please wait for the game to start.
    }
  }
  ;----------------------------------------------------------------------------------------------------FDROP
  elseif ($1 == .fdrop) { 
    if ($isappmod($nick)) {
      if ($aget(drop)) {
        if ($v1 == $$2) {
          .timer $+ $network $+ app28 off
          drop
        }
        else {
          msg $appchan Please wait for a response from $aget(drop)
        }
      }
      elseif ($2 isin $aget(players)) {
        hadd $aname drop $2
        drop
      }
      else {
        .msg $appchan $2 is not playing the game.
      }
    }
    else {
      .msg $appchan You need to be a Game Mod to use that command.
    }
  }
  ;-----------------------------------------------------------------------------------------------------HERE
  elseif ($1 == .here) { 
    if ($nick == $aget(drop)) {
      .timer $+ $network $+ app28 off
      .msg $appchan $nick $+ , you are still in the game.
      hdel $aname drop
    }
  }
  ;----------------------------------------------------------------------------------------------------HELP
  elseif ($1 == .help) {
    apphelp $nick $2-
  }
  ;-----------------------------------------------------------------------------------------------------APPCMDS
  elseif ($1 == .appcmds) { 
    var %ln = 1
    .msg $nick Apples Commands:
    while (%ln <= 12) {
      msg $nick $read(apples\apples.txt,%ln)
      inc %ln
    }
    if ($appop($network,extcrd)) {
      if ($appop($network,modadd) == 0) {
        msg $nick $read(apples\apples.txt,13)
      }
    }
    if ($isappmod($nick)) {
      if ($appop($network,extcrd) == 1 ) {
        if ($appop($network,modadd) == 1) {
          .msg $nick $read(apples\apples.txt,13)
        }
        msg $nick $read(apples\apples.txt,14)
      }
      msg $nick $read(apples\apples.txt,15)
    }
  }
  ;----------------------------------------------------------------------------------------------------TOTAL
  elseif ($1 == .total) || ($$1 == .tot) { 
    if ($$2- == red) || ($$2 == r) {
      var %d = $lines(apples\red.txt) + $iif($appop($network,extcrd),$lines(apples\ $+ $network $+ \ $+ red.txt),0)
      .msg $chan There are %d 4red cards.
    }
    elseif ($$2 == green) || ($$2 == g) {
      var %d = $lines(apples\green.txt) + $iif($appop($network,extcrd),$lines(apples\ $+ $network $+ \ $+ green.txt),0)
      .msg $chan There are %d 3green cards.
    }
  }
  ;-----------------------------------------------------------------------------------------------------GREENS
  elseif ($1 == .green) || ($1 == .greens) {
    if ($hget($aname)) {
      if (!$2) {
        if ($hget($aname,$nick $+ .green)) {
          .msg $chan $nick has $hget($aname,$nick $+ .scr) green cards:3 $v1
        }
        else {
          .msg $chan $nick doesn't have any green cards.
        }
      }
      else {
        if ($hget($aname,$2 $+ .green)) {   
          .msg $chan $2 has $hget($aname,$2 $+ .scr) green cards:3 $hget($aname,$2 $+ .green)
        }
        else {
          .msg $chan $2 doesn't have any green cards this game.
        }
      }
    }
    else {
      .msg $chan There is currently no game running.
    }
  }
  ;-------------------------------------------------------------------------------------------------------------BUGS
  elseif ($1 == .bug) || ($1 == .bugs) { 
    if (!$2) {
      .fopen bugs apples\bugs.txt
      while (!$fopen(bugs).eof) {
        .msg $appchan $fread(bugs)
      }
      .fclose bugs
    }
    else {
      write apples\newbugs.txt $chr(91) $+ $date $time $+ $chr(93) $nick $+ : $2-
      .msg $appchan $nick $+ : your bug has been reported.
      alog New bug reported
    }
  }
  ;-------------------------------------------------------------------------------------------------------------PLAYERS
  elseif ($1 == .players) { 
    if ($aget()) {
      msg # Players: $applayerlist()
    }
    else {
      .msg $chan No game in progress
    }
  }
  ;-------------------------------------------------------------------------------------------------------------SCORES
  elseif ($1 == .score) || ($1 == .scores) { 
    if (!$timer(appscr)) {
      scrlst $2
      .timerappscr 30 1 noop
    }
  }
  ;-------------------------------------------------------------------------------------------------------------PINGCHAN
  elseif ($1 == .pingchan) {
    if ($timer(appping) == $null) {
      apphl
      timerappping 1 300 .noop
    }
  }
  ;-------------------------------------------------------------------------------------------------------------reserves
  elseif ($1 == .res) || ($1 == .reserves) {
    if ($hget($cname)) {
      .msg $appchan Card reserves:4 $calc(100 * $rcards(r)) $+ $chr(37) 3 $calc(100 * $rcards(g)) $+ $chr(37)
    }
    else {
      .msg $appchan There are no cards currently loded.
    }
  }
  ;-------------------------------------------------------------------------------------------------------------search
  elseif ($1 == .search) {
    cardsearch $nick $$2-
  }
  ;-------------------------------------------------------------------------------------------------------------refresh
  elseif ($1 == .refresh) {
    if (!hget($aname)) {
      if ($hget($cname)) {
        if ($isappmod($nick)) {
          if ($left($2,1) == r) {
            var %col = 4Red
          }
          elseif ($left($2,1) == g) {
            var %col = 3Green
          }
          apref $left($2,1)
          msg $chan %col card list has been refreshed.
        }
        else {
          msg $chan You must be a GameMod to use that command.
        }
      }
      else {
        msg $appchan There are no cards loaded.
      }
    }
    else {
      msg $appchan You cannot refresh the cards during a game.
    }
  }
  else {
    if ($1 == .apples) {
      msg # Please go to $appchan to play Apples to Apples.
    }
  }
}
;----------------------------------------------------------------------------- MESSAGES
on *:TEXT:*:?: { 
  if ($1 == .help) {
    apphelp $nick $2
  }
  elseif ($1 == .search) {
    cardsearch $nick $2-
  }
  elseif ($aget()) {
    if ($nick !isin $aget(players)) {
      .msg $nick you are not in the game, please type .join in $appchan to join the game.
    }
    ;---------------------------------------------------------------------Vote
    else { 
      if ($aget(phase) == vote) { 
        if ($nick == $gettok($aget(subs),$int($1),131)) {
          .msg $nick you cannot vote for yourself.
        }
        elseif ($int($1) isnum 1- $numtok($aget(subs),131)) {
          if ($aget(mode) == allvote) {
            vote $int($1) $nick p
          }
          elseif ($nick == $applayer($aget(judge))) {
            vote $int($1) $nick
          }
          else {
            .msg $nick You are not the judge.
          }
        }
        else {
          .msg $nick That is not a valid choice
        }
      }
      ;--------------------------------------------------------------------------Submit
      elseif ($hget($aname,phase) == submit) { 
        if ($nick == $applayer($aget(judge))) {
          .msg $nick You are the judge, you cannot submit a card this round.
        }    
        elseif ($int($1) !isnum 1-7) {
          .msg $nick That is not a valid choice, please use the number.
        }
        else {
          var %player = $nick
          var %sub = $int($1)
          if ($numtok($aget(%player),131) == 9) { 
            .msg $nick You have changed your submission to:4 $int($1) $+ $chr(58) $redn(%player,%sub)
            hadd $aname %player $puttok($aget(%player),$int($$1),9,131)
          }
          else {
            hadd $aname %player $instok($aget(%player),$int($$1),9,131)
            hadd $aname subs $addtok($aget(subs),%player,131)
            .msg $nick 4 $int($1) $+ $chr(58) $redn(%player,%sub) has been submitted.
            if ($aget(mode) == allvote) {
              if ($numtok($aget(subs),131) == $applayer()) {
                .timer $+ $network $+ app24 off
                .timer $+ $network $+ app26 off
                reveal
              }
            }
            else {
              if ($calc($applayer() - 1) == $numtok($aget(subs),131)) {
                .timer $+ $network $+ app24 off
                .timer $+ $network $+ app26 off
                reveal
              }
            }
          }
        }
      }
    }
  }
}
on *:NICK: {
  if ($aget($nick)) {
    hadd $aname $newnick $aget($nick)
    hdel $aget $nick
  }
  if ($nick isin $aget(players)) {
    hadd $aname players $reptok($aget(players),$nick,$newnick,1,131)
  }
}
;----------------------------------------------------------------------------------------------------
;------------------------------------------------ALIASES---------------------------------------------
;----------------------------------------------------------------------------------------------------

;-------------------------------------------------------------------------------greens
alias greens {
  var %n = 1 
  while (%n <= $applayer()) {
    var %p = $applayer(%n)
    .msg %p You had the following green cards: 3 $+ $aget(%p $+ .green)
    inc %n
  }
}

;-------------------------------------------------------------------------------Sortscore
alias sortscore {
  var %nn = 1
  var %list
  while (%nn <= $applayer()) {
    var %p = $applayer(%nn)
    var %e = $gettok($aget(%p),8,131) $+ $chr(131) $+ %p
    %list = $addtok(%list,%e,46)
    inc %nn
  }
  var %scrs = $sorttok(%list,46,nr)
  if ($1 isnum) {
    return $gettok(%scrs,$1,46)
  }
  else {
    return %scrs
  }
}
;-------------------------------------------------------------------------------appwincheck
alias appwincheck {
  var %scrs = $sortscore
  var %n = 1
  while (%n <= $numtok(%scrs,46)) {
    var %sc = $gettok(%scrs,%n,46)
    var %sclst = %sclst $ord(%n) $+ : $gettok(%sc,2,131) $+ - $+ $gettok(%sc,1,131)
    inc %n
  }
  if ($aget(rounds)) {
    if ($aget(round) == $aget(rounds)) {
      msg $appchan GAME OVER!
      var %winner = $gettok($sortscore(1),2,131)
      msg $appchan Final scores: %sclst
      writeini -n apples\score.ini $network %winner $calc($readini(apples\score.ini,$network,%winner) + 1)
      msg $appchan %winner has won their $ord($readini(apples\score.ini,$network,%winner)) game of apples with:3 $aget(%winner $+ .green)
      greens
      appoff
    }
    else {
      msg $appchan End of round $aget(round) of $aget(rounds)
      msg $appchan Scores: %sclst
      .timer $+ $network $+ app26 1 10 /round
      hinc $aname judge
      if ($aget(judge) > $applayer()) {
        hadd $aname judge 1
      }
      hadd $aname phase 0
      hdel $aname subs
    }
  }
  else {
    if ($gettok($sortscore(1),1,131) >= $aget(wins)) {
      var %winner = $gettok($sortscore(1),2,131)
      if ($calc($gettok($sortscore(1),1,131) - 1) > $gettok($sortscore(2),1,131)) {        
        writeini -n apples\score.ini $network %winner $calc($readini(apples\score.ini,$network,%winner) + 1)
        msg $appchan %winner has won their $ord($readini(apples\score.ini,$network,%winner)) game of apples with:3 $aget(%winner $+ .green)
        msg $appchan Final Scores: %sclst
        if ($aget(mode) != allvote) {
          greens
        }
        appoff
      }
      else {
        msg $appchan End of round $aget(round) $+ . Scores: %sclst $+ . Playing to: $aget(wins)
        msg $appchan %winner $+ , you must win by 2 points.
        .timer $+ $network $+ app26 1 10 /round
        hinc $aname judge
        if ($aget(judge) > $applayer()) {
          hadd $aname judge 1
        }
        hdel $aname subs
        hadd $aname phase 0
      }
    }
    else {
      msg $appchan End of round $aget(round) $+ . Scores: %sclst $+ . Playing to: $aget(wins)
      .timer $+ $network $+ app26 1 10 /round
      if ($aget(mode) != allvote) {
        hinc $aname judge
        if ($aget(judge) > $applayer()) {
          hadd $aname judge 1
        }
        hadd $aname phase 0
        hdel $aname subs
      }
    }
  }
}
;-------------------------------------------------------------------------------avend
alias avend { 
  msg $appchan Polls are closed. Results are in:
  var %vn = 1
  while (%vn <= $numtok($aget(subs),131)) {
    var %nick = $gettok(
    var %mm = %nick $+ 's card4 $aget(sub $+ %vn) got $aget(sub $+ %vn $+ .v) votes.
    if (!$aget(%nick $+ .v)) {
      hadd $aname sub $+ %vn $+ .v 0
      var %mm = %mm But they didn't vote, so they don't get any points.
    }
    else {
      hinc $aname %nick $+ .scr $aget(sub $+ %vn $+ .v)
    }
    msg $appchan %mm
    inc %vn 
  }
  hdel -w $aname *.v
  hdel -w $aname *.subnum
  var %d = 1
  while (%d < $aget(subs)) {
    hdel -w $aname sub $+ %d $+ *
    inc %d
  }
  redraw
  hdel $aname votes
  appwincheck
}
;-------------------------------------------------------------------------------vote
alias vote {
  if ($aget(mode) == allvote) {
    var %n = $2
    if ($aget(%n $+ .v)) {
      if ($3 == c) {
        msg $appchan %n $+ : You have already voted.
      }
      else {
        msg %n You have already voted.
      }
    }
    else {
      hinc $aname sub $+ $1 $+ .v 
      hadd $aname %n $+ .v $1
      hinc $aname votes
      msg %n You have voted for4 $aget(sub $+ $1)
      if ($aget(votes) >= $aget(players)) {
        .timer $+ $network $+ app22 off
        .timer $+ $network $+ app29 off
        avend      
      }
    }
  }
  else {
    winner $1
  } 
}
;-------------------------------------------------------------------------------appjoin
alias appjoin {
  if ($1 !isin $aget(players)) {
    hadd $aname players $addtok($aget(players),$1,131)
    msg $appchan $1 $+ , you are now in the game.
    alog Player Joined: $1
    mode $appchan +v $1
  }
  if (!$aget($$1)) {
    hadd $aname $1 1솢쭼핖�0
    if ($aget(phase) != join) {
      draw $1
      reds $1
    }
  }
  if ($aget(phase) == pause) {
    if ($applayer() >= 3) {
      appresume
    }
  }
}
;-------------------------------------------------------------------------------appresume
alias appresume {
  .msg $appchan Minimum Players reached. The game will now continue.
  .msg $appchan Players are: $applayerlist()
  round
}
;-------------------------------------------------------------------------------drop
alias drop { 
  if ($aget(drop)) {
    var %dname = $V1
    msg # %dname has been removed from the game.
    if ($aget(judge) == $applayer(%dname)) {
      var %nj = 1
    }
    elseif ($aget(judge) > $applayer(%dname)) {
      hdec $aname judge 
    }
    if ($aget(judge) > $applayer()) {
      hadd $aname judge 1
    }
    hadd $aname players $remtok($aget(players),%dname,1,131)
    hadd $aname %dname $deltok($aget(%dname),9,131)
    hadd $aname subs $remtok($aget(subs),$applayer($aget(judge)),1,131)
    if ($numtok($aget(%dname),131) = 9) {
      hadd $aname $applayer(judge) $deltok($applayer($aget(judge)),9,131)
      msh $appchan Submissions have changed.
      reveal
    }
    hdel $aname drop
    if (%nj) {
      msg $appchan %dname was the judge, $applayer($aget(judge)) is now the judge.
    }
    if ($applayer() < 3) {
      hadd $aname phase pause
      msg $appchan Not enough players to continue, pausing. The game will resume if more players join.
      .timer $+ $network $+ app2? off
    }
  } 
}
;-------------------------------------------------------------------------------alog
alias alog {
  var %t = $timestamp ( $+ $network $+ ) $1-  
  window @AppLog
  aline -p @applog %t
  var %f = " $+ $mircdir $+ \apples\log.txt $+ "
  write %f %t
  while ($file(%f).size > 51200) {
    write -dl1 %f
  }
}
;-------------------------------------------------------------------------------notify
alias notify {
  var %file = $eval($mircdir $+ apples\ $+ $network $+ \ $+ notify.txt)  
  var %num = $lines(%file)
  var %n = 1
  while (%n <= %num) {
    notice $read(%file,%n) A new game of apples is about to start in $appchan
    inc %n
  }
}
;-------------------------------------------------------------------------------appstart
alias appstart {
  if (!$hget($cname)) {  
    alog No cards, Loading list
    cardlist
  }
  else {
    alog Card reserves:4 $calc(100 * $rcards(r)) $+ $chr(37) 3 $calc(100 * $rcards(g)) $+ $chr(37)
    if ($rcards(r) < .33) {
      alog Refreshing Red Card list.
      hdel $cname totr
      hdel -w $cname red*
      cardlist red
    }
    if ($rcards(g) < .33) {
      alog Refreshing Green Card list.
      hdel $cname totg
      hdel -w $cname green*
      cardlist green
    }
  }
  hadd $aname phase join
  hadd $aname jointime $appop($network,jtime)
  hadd $aname roundtime $appop($network,rtime)
  hadd $aname dtime $appop($network,dtime)
  var %app2 = $hget($aname,jointime) - 10
  .msg $appchan A new game of Apples is about to start.
  .msg $appchan $read($mircdir $+ apples\rules.txt)
  .msg $appchan Please type .join to join. The game will start in $duration($hget($aname,jointime)) $+ .
  if ($aget(rounds)) {
    var %start = Playing $aget(rounds) rounds.
  }
  else {
    var %start = Playing to $aget(wins) points.
  }
  if ($aget(mode) == double) {
    var %start = %start 3DOUBLE GREEN MODE!
  }
  elseif ($aget(mode) == allvote) {
    var %start = %start EVERYONE VOTES MODE!
  }
  msg $appchan %start
  .timer $+ $network $+ app20 1 %app2 /.msg $appchan The Game will start in 10 seconds.
  .timer $+ $network $+ app21 1 $hget($aname,jointime) /firstround
}
;-------------------------------------------------------------------------------firstround
alias firstround {
  if ($aget(mode) != allvote) {
    hadd $aname judge $rand(1,$applayer())
  }
  hadd $aname phase 0
  .msg $appchan The game is starting. You may still join at anytime by typing .join
  .msg $appchan Players: $applayerlist()
  if ($applayer() < 3) {
    .msg $appchan I am sorry, this game requires $V2 or more players.
    alog Terminated: Not enough players
    appoff
  }
  else {
    var %dn = 1
    while (%dn <= $applayer()) {
      draw $gettok($aget(players),%dn,131)
      inc %dn
    }
    hadd $aname round 0
    alog Game Started: Players: $applayerlist()
    round
  }
}
;-------------------------------------------------------------------------------round
alias round {
  hinc $aname round
  if ($rand(1,100) < 2) || ($aget(mode) == double) {
    var %num = $rand(1,$hget($cname,totg))
    while (!$hget($cname,green $+ %num)) {
      %num = $rand(1,$hget($cname,totg))
    }
    var %g1 = $hget($cname,green $+ %num)
    hdel $cname $eval(green $+ %num)
    var %num = $rand(1,$hget($cname,totg))
    while (!$hget($cname,green $+ %num)) {
      %num = $rand(1,$hget($cname,totg))
    }
    var %g2 = $hget($cname,green $+ %num)
    hdel $cname $eval(green $+ %num)
    hadd $aname green ' $+ %g1 $+ ' and ' $+ %g2 $+ '
    if ($aget(mode) != double) {
      alog Round $hget($aname,round) $+ : 2Begin 3DOUBLE GREENS!
      msg $appchan SPECIAL ROUND: Double Green Cards!
    }
  }
  else {
    var %num = $rand(1,$hget($cname,totg))
    while (!$hget($cname,green $+ %num)) {
      %num = $rand(1,$hget($cname,totg))
    }
    hadd $aname green $hget($cname,green $+ %num)
    hdel $cname $eval(green $+ %num)
    alog Round $aget(round) $+ : 2Begin
  }
  var %nm = 1
  while (%nm <= $applayer()) {
    if (%nm != $aget(judge)) {
      reds $applayer(%nm)
    }
    elseif ($aget(round) == 1) {
      reds $applayer(%nm) 1
    }
    inc %nm
  }
  hadd $aname phase submit
  if ($aget(rounds)) {
    var %rnd = $aget(round) of $aget(rounds)
  }
  else {
    var %rnd = $aget(round) 
  }
  if ($aget(mode) == allvote) {
    .msg $appchan Round %rnd $+ , Topic:3 $aget(green) $+ . You have $aget(roundtime) seconds to $chr(47) $+ msg me your choice.
  }
  else {
    .msg $appchan Round %rnd $+ , $applayer($aget(judge)) is the Judge. Topic:3 $aget(green) $+ . You have $aget(roundtime) seconds to $chr(47) $+ msg me your choice.
  }
  alog Round $aget(round) $+ : 2Submissions
  .timer $+ $network $+ app24 1 $aget(roundtime) reveal
  .timer $+ $network $+ app26 1 $calc($aget(roundtime) - 20) poke
}
;-------------------------------------------------------------------------------reveal
alias reveal {
  if (!$aget(subs)) {
    .msg $appchan No cards were submitted this round, next round will begin in 10 seconds.
    if ($aget(mode) != allvote) {
      hinc $aname judge
      if ($aget(judge) > $applayer()) {
        hadd $aname judge 1
      }
    }
    .timer $+ $network $+ app27 1 10 /round
  }
  elseif ($numtok($aget(subs),131) == 1) {
    .msg $appchan $aget(subs) was the only player to submit a card this round.
    winner 1
  }
  else {
    hadd $aname phase 0
    hadd $aname subs $shufftok($aget(subs),131)
    if ($aget(mode) == allvote) {
      .msg $appchan Submissions are in. Plese choose your favoite example of3 $hget($aname,green) $+ .
    }
    else {
      .msg $appchan Submissions are in. $applayer($aget(judge)) $+ , you have $duration($hget($aname,roundtime)) to $chr(47) $+ msg me your favorite example of3 $hget($aname,green) $+ .
    }
    var %revnum = 1
    var %glist
    while (%revnum <= $numtok($aget(subs),131)) {
      var %name = $gettok($aget(subs),%revnum,131)
      var %card = $redn(%name,$gettok($aget(%name),9,131))
      .msg $appchan %revnum $+ $chr(58)4 %card
      %glist = %glist %revnum $+ $chr(58)4 %card
      inc %revnum
    }
    if ($aget(mode) == allvote) {
      var %msn = 1
      while (%msn <= $applayer()) {
        .msg $applayer(%msn) Choose your favorite example of3 $aget(green) : %glist
        inc %msn
      }
    }
    else {
      .msg $applayer($aget(judge)) Choose your favorite example of3 $aget(green) : %glist
    }
    hadd $aname phase vote
    alog Round $hget($aname,round) $+ : 2Vote
    var %vtime = $aget(roundtime)
    if ($aget(subs) > 3) {
      var %vtime = %vtime + 30
    }
    if ($aget(mode) != allvote) {
      .timer $+ $network $+ app22 1 $calc(%vtime - 30) /.msg $appchan $applayer($aget(judge)) $+ : you have 30 sec to make your choice.
      .timer $+ $network $+ app29 1 %vtime /newjudge
    }
    else {
      .timer $+ $network $+ app29 1 $calc(%vtime - 30) /msg $appchan 30 seconds left to cast your votes.
      .timer $+ $network $+ app22 1 %vtime avend 
    }
  }
}
;-------------------------------------------------------------------------------draw
alias draw {
  var %name = $$1
  var %cardnum = 1
  while (%cardnum <= 7 ) {
    var %num = $rand(1,$hget($cname,totr))
    while (!$hget($cname,red $+ %num)) {
      %num = $rand(1,$hget($cname,totr))
    }
    hadd $aname %name $puttok($aget(%name),$hget($cname,red $+ %num),%cardnum,131)
    hdel $cname $eval(red $+ %num)
    inc %cardnum
  }
}
;-------------------------------------------------------------------------------reds
alias reds {  
  var %p = $$1
  var %n = 1
  var %c = Your Cards: 
  while (%n <= 7) {
    %c = %c 4 %n $+ : $redn(%p,%n)
    inc %n
  }
  if ($2 == 1) {
    .msg %p %c
  }
  else {
    if ($aget(mode) == allvote) {
      .msg %p Green card:3 $hget($aname,green) $+ . %c
    }
    else {
      .msg %p Green card:3 $hget($aname,green) $+ . Judge:2 $applayer($aget(judge)) $+ . %c
    }
  }
}
;-------------------------------------------------------------------------------cards
alias cards {
  var %n = 1
  while (%n <= $applayer()) {
    if (%n != $aget(judge)) {
      reds $applayer(%n)
    }
    inc %n
  }
}
;-------------------------------------------------------------------------------redn
alias redn {
  return $gettok($aget($$1),$$2,131)
} 
;-------------------------------------------------------------------------------redraw
alias redraw {
  var %plnum = 1
  while (%plnum <= $applayer()) {
    var %name = $applayer(%plnum)
    if ($numtok($aget(%name),131) == 9) {
      var %cardnum = $gettok($aget(%name),9,131)
      var %num = $rand(1,$hget($cname,totr))
      while (!$hget($cname,red $+ %num)) {
        %num = $rand(1,$hget($cname,totr))
      }
      var %newword = $hget($cname,red $+ %num)
      hdel $cname $eval(red $+ %num)
      hadd $aname %name $puttok($aget(%name),%newword,%cardnum,131)
      hadd $aname %name $deltok($aget(%name),9,131)
      .msg %name You drew: %newword
    }
    inc %plnum
  }
}
;-------------------------------------------------------------------------------apref
alias apref {
  if ($1 == r) {
    hdel $cname totr
    hdel -w $cname red*
    cardlist r
  }
  elseif ($1 == g) {
    hdel $cname totg
    hdel -w $cname green*
    cardlist g
  }
}
;-------------------------------------------------------------------------------cardlist
alias cardlist {
  if (!$hget($cname)) {
    hmake $cname 200
  }
  if ($1 == r) || ($1 == red) || (!$1) {
    var %num = 1
    .fopen red apples\red.txt
    while ($fopen(red).eof == 0) {
      hadd $cname $eval(red $+ %num) $fread(red)
      inc %num
    }
    .fclose red
    if ($appop($network,extcrd)) {
      .fopen reda apples\ $+ $network $+ \ $+ red.txt
      while ($fopen(reda).eof == 0) {
        hadd $cname $eval(red $+ %num) $fread(reda)
        inc %num
      }
      .fclose reda
    }
    hadd $cname totr $hfind($cname,r*,0,w)
  }
  if ($1 == g) || ($1 == green) || (!$1) {
    var %num = 1
    .fopen green apples\green.txt
    while ($fopen(green).eof == 0) {
      hadd $cname $eval(green $+ %num) $fread(green)
      inc %num
    }
    .fclose green
    if ($appop($network,extcrd)) {
      .fopen greena apples\ $+ $network $+ \ $+ green.txt
      while ($fopen(greena).eof == 0) {
        hadd $cname $eval(green $+ %num) $fread(greena)
        inc %num
      }
      .fclose greena
    }
    hadd $cname totg $hfind($cname,g*,0,w)
  }
}
;-------------------------------------------------------------------------------poke
alias poke {
  var %n = $applayer()
  while (%n > 0) {
    if (%n != $aget(judge)) {
      var %name = $applayer(%n)
      if ($numtok($aget(%name),131) != 9) {
        var %l = %l %name
      }
    }
    dec %n
  }
  msg $appchan %l you have 20 seconds to message me your choice
}
;-------------------------------------------------------------------------------drawgrn
alias drawgrn {
  var %num = $rand(1,$hget($cname,totg)) 
  while (!$hget($cname,green $+ %num)) {
    echo . %num
    %num = $rand(1,$hget($cname,totg))
  }
  echo . %num : $hget($cname,green $+ %num)
  hdel $cname $eval(green $+ %num)
}
;-------------------------------------------------------------------------------newjudge
alias newjudge {
  var %old = $applayer($aget(judge))
  hinc $aname judge
  if ($aget(judge) > $applayer()) {
    hadd $aname judge 1
  }
  .msg $appchan %old is apparently too busy to play. $applayer($aget(judge)) is the new judge, you have $aget(roundtime) seconds to make your choice.
  var %revnum = 1
  var %glist
  while (%revnum <= $numtok($aget(subs),131)) {
    var %name = $gettok($aget(subs),%revnum,131)
    var %card = $redn(%name,$gettok($aname(%name),9,131))
    %glist = %glist %revnum $+ $chr(58)4 %card
    inc %revnum
  }
  .msg $applayer($aget(judge)) %old did not choose a card, you are now judge. Please choose your favorite example of 3' $+ $aget(green) $+ ' : %glist
  .timer $+ $network $+ app22 1 $calc($hget($aname,roundtime) - 15) /.msg $appchan $applayer($aget(judge)) $+ : you have 15 sec to make your choice.
  .timer $+ $network $+ app29 1 $hget($aname,roundtime) /newjudge
}
;-------------------------------------------------------------------------------appoff
alias appoff { 
  .msg $appchan Apples is shutting down.
  .timer $+ $network $+ app2? off
  hfree $aname
  devoice
  close -m
}
;-------------------------------------------------------------------------------devoice
alias devoice {
  var %n = 1
  while (%n <= $nick($appchan,0,v)) {
    mode $appchan -v $nick($appchan,%n,v)
    inc %n
  }
}
;-------------------------------------------------------------------------------cc
alias cc {
  if ($$1 == r) || ($$1 == red) {
    .fopen cards apples\red.txt
    while (!$fopen(cards).eof) {
      if ($$2- == $fread(cards)) {
        .fclose cards        
        return 1
      }
    }
    .fclose cards
    .fopen cards apples\ $+ $network $+ \ $+ red.txt
    while (!$fopen(cards).eof) {
      if ($$2- == $fread(cards)) {
        .fclose cards
        return 1
      }
    }
    .fclose cards
  }
  elseif ($$1 == g) || ($$1 == green) {
    .fopen cards apples\green.txt
    while (!$fopen(cards).eof) {
      if ($$2- == $fread(cards)) {
        .fclose cards        
        return 1
      }
    }
    .fclose cards
    .fopen cards apples\ $+ $network $+ \ $+ green.txt
    while (!$fopen(cards).eof) {
      if ($$2- == $fread(cards)) {
        .fclose cards
        return 1
      }
    }
    .fclose cards
  }
}
;-------------------------------------------------------------------------------winner
alias winner {
  .timer $+ $network $+ app29 off
  var %winplyr = $gettok($aget(subs),$1,131)
  var %winword = $redn(%winplyr,$gettok($aget(%winplyr),9,131))
  hadd $aname %winplyr $puttok($aget(%winplyr),$calc($gettok($aget(%winplyr),8,131) + 1),8,131))
  .msg $appchan %winplyr wins with: 4 $+ %winword $+ , and receives the3 $aget(green) card
  if ($hget($aname,%winplyr $+ .scr) == 1) {
    hadd $aname %winplyr $+ .green $hget($aname,green)
  }
  else {
    hadd $aname %winplyr $+ .green $aget(%winplyr $+ .green) $+ , $hget($aname,green) 
  }
  .timer $+ $network $+ app22 off
  var %dn = $aget(subs)
  redraw
  appwincheck
}
;-------------------------------------------------------------------------------scrnum
alias scrnum {
  var %num = 1
  var %list
  while (%num <= $ini(apples\score.ini,$network,0)) {
    var %name = $ini(apples\score.ini,$network,%num)
    var %scr = $readini(apples\score.ini,$network,%name)
    if (%num <= 10) {
      var %list = $addtok(%list,%scr $+ / $+ %name,46)
      var %list = $sorttok(%list,46,nr)
    }
    else {
      var %last = $gettok($gettok(%list,10,46),1,47)
      if (%scr > %last) {
        var %list = $puttok(%list,%scr $+ / $+ %name,10,46)
        var %list = $sorttok(%list,46,nr)
      }
    }
    inc %num
  }
  var %scn = $gettok(%list,$$1,46)
  var %nl = $len(%scn)
  var %ln = $calc(19- %nl)
  return $gettok(%scn,2,47) $str(.,%ln) $gettok(%scn,1,47)
}
;-------------------------------------------------------------------------------scrlst
alias scrlst {
  if (!$1) {
    .msg $appchan Top 10 Scores for $network $+ :
    .msg $appchan 1) $scrnum(1) :: 6) $scrnum(6)
    .msg $appchan 2) $scrnum(2) :: 7) $scrnum(7)
    .msg $appchan 3) $scrnum(3) :: 8) $scrnum(8)
    .msg $appchan 4) $scrnum(4) :: 9) $scrnum(9)
    .msg $appchan 5) $scrnum(5) ::10) $scrnum(10) 
  }
  else {
    var %scn = 1
    while (%scn <= $ini(apples\score.ini,$network,0)) {
      var %scrs = %scrs $+ $readini(apples\score.ini,$network,$ini(apples\score.ini,$network,%scn)) $+ $chr(165) $+ $ini(apples\score.ini,$network,%scn) $+ $chr(131)
      inc %scn
    }
    var %scrs = $sorttok(%scrs,131,nr)
    if ($1 isin %scrs) {
      var %scnu = $wildtok(%scrs,* $+ $1,1,131)
      var %place = $findtok(%scrs,%scnu,1,131)
      msg $appchan $gettok(%scnu,2,165) is in $ord(%place) place with $gettok(%scnu,1,165) games won.
    }
    else {
      msg $appchan $1 has not won any games of apples on this server.
    }
  }
}
;-------------------------------------------------------------------------------cardsearch
alias cardsearch {
  var %nick = $1
  if ($left($2,1) == r) {
    var %wild = * $+ $replace($$3-,$chr(32),*) $+ *
    var %eof = $lines(apples\red.txt)
    var %ln = 1
    var %n = 0
    while ($read(apples\red.txt,w,%wild,%ln)) {
      if (%n < 5) {
        var %results = %results 4 $+ $read(apples\red.txt,w,%wild,%ln) |
      }
      var %ln = $readn + 1
      inc %n
    }
    msg %nick Found %n results for4 %wild in the core set. First 5: $left(%results,-1)
    if ($appop($network,extcrd)) {
      unset %results
      var %wild = * $+ $replace($$3-,$chr(32),*) $+ *
      var %eof = $lines(apples\ $+ $network $+ \ $+ red.txt)
      var %ln = 1
      var %n = 0
      while ($read(apples\ $+ $network $+ \ $+ red.txt,w,%wild,%ln)) {
        if (%n < 5) {
          var %results = %results 4 $+ $read(apples\ $+ $network $+ \ $+ red.txt,w,%wild,%ln) |
        }
        var %ln = $readn + 1
        inc %n
      }
      msg %nick Found %n results for4 %wild in the added set. First 5: $left(%results,-1)
    }
  }
  elseif ($left($2,1) == g) {
    var %wild = * $+ $replace($$3-,$chr(32),*) $+ *
    var %eof = $lines(apples\green.txt)
    var %ln = 1
    var %n = 0
    while ($read(apples\green.txt,w,%wild,%ln)) {
      if (%n < 5) {
        var %results = %results 3 $+ $read(apples\green.txt,w,%wild,%ln) |
      }
      var %ln = $readn + 1
      inc %n
    }
    msg $nick Found %n results for3 %wild in the core set. First 5: $left(%results,-1)
    if ($appop($network,extcrd)) {
      unset %results
      var %wild = * $+ $replace($$3-,$chr(32),*) $+ *
      var %eof = $lines(apples\ $+ $network $+ \ $+ green.txt)
      var %ln = 1
      var %n = 0
      while ($read(apples\ $+ $network $+ g.txt,w,%wild,%ln)) {
        if (%n < 5) {
          var %results = %results 3 $+ $read(apples\ $+ $network $+ \ $+ green.txt,w,%wild,%ln) |
        }
        var %ln = $readn + 1
        inc %n
      }
      msg %nick Found %n results for3 %wild in the added set. First 5: $left(%results,-1)
    }  
  }
}
;-------------------------------------------------------------------------------apphl
alias apphl {
  var %t = $nick($appchan,0)
  var %n = 1
  while (%n <= %t) {
    var %list = %list $nick($appchan,%n)
    inc %n
  }
  msg $appchan %list
}
;-------------------------------------------------------------------------------isclean
alias isclean {
  var %n = $len($$1-)
  while (%n >= 0) {
    if ($mid($1-,%n,1) !isin abcdefghijklmnopqrstuvwxyz1234567890 /\:;'",._-+=?!) {
      return $false
    }
    dec %n
  }
  return $true
}
;-------------------------------------------------------------------------------checkchan
alias checkchan {
  if ($appchan !ischan) {
    join $V1
    .timer 1 10 /checkchan
  }
  else {
    .timer 0 900 /checkchan
  }
}
;-------------------------------------------------------------------------------apphelp
alias apphelp {
  if (!$2) {
    .msg $$1 $read(apples\rules.txt)
    .msg $$1 4.apples <N> Starts a game with winning score <N>(max: 25), default is 5
    .msg $$1 4.join Joins a game in progress, may be used anytime a game is in progress.
    .msg $$1 Additional commands: 4.addcard .remcard .drop .quit .fdrop .fstart .fjoin .wins .greens .check .notify .here .help .total .players .scores .search
    .msg $$1 4.help <command> for more help
  }
  elseif ($2 == .apples) {
    .msg $$1 .apples
    .msg $$1 Syntax: .apples <n>
    .msg $$1 Use: Starts a game with score given. If blank, it will default to 5. Max 25
  }
  elseif ($2 == .join) {
    .msg $$1 .join
    .msg $$1 Syntax: .join
    .msg $$1 Use: Join a game in progress
  }
  elseif ($2 == .addcard) {
    .msg $$1 .addcard
    .msg $$1 Syntax: .addcard <color> <card>
    .msg $$1 Use: Creates card of specified color. (Please use title case ie: 'Birthday Cake' not 'birthdy cake')
  }
  elseif ($2 == .remcard) {
    .msg $$1 .remcard
    .msg $$1 Syntax: .remcard <color> <card>
    .msg $$1 Use: Removes specified card. Cannot be used to remove cards from the core list.
  }
  elseif ($2 == .drop) {
    .msg $$1 .drop
    .msg $$1 Syntax: .drop <player>
    .msg $$1 Use: Begins the drop process. The given player is given $appop($network,dtime) seconds to respond with .here or they will be removed from the game.
    .msg $$1 If <player> is yourself or "me", the drop will be instant
  }
  elseif ($2 == .quit) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .quit
    .msg $$1 Use: Removes you from the current game. You can rejoin the game at any time with the same score and cards.
  }
  elseif ($2 == .fdrop) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .fdrop <player>
    .msg $$1 Use: /!\ MODS ONLY /!\ Drops the specified player without delay
  }
  elseif ($2 == .fstart) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .fstart
    .msg $$1 Use: /!\ MODS ONLY /!\ Force starts the game, as long as the appropriate number of players have joined.
  }
  elseif ($2 == .fjoin) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .fjoin <player>
    .msg $$1 Use: /!\ MODS ONLY /!\ Force joins the nick.
  }
  elseif ($2 == .wins) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .wins <player>
    .msg $$1 Use: Shows the total number of games <player> have won on the given server. If blank, shows your games won.
  }
  elseif ($2 == .greens) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .greens <player>
    .msg $$1 Use: Shows the green cards won by <player> in current game. If blank, shows your own green cards.
  }
  elseif ($2 == .check) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .check <color> <card>
    .msg $$1 Use: Checks the card list for specified card (exact match only).
  }
  elseif ($2 == .notify) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .notify
    .msg $$1 Use: :TOGGLE: Turns on/off new game notifications.
  }
  elseif ($2 == .here) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .here
    .msg $$1 Use: Keeps you in the game if the .drop command is used.
  }
  elseif ($2 == .help) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .help
    .msg $$1 Use: You know, I am really not sure what this one does...
  }
  elseif ($2 == .total) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .total <color>
    .msg $$1 Use: Displays the total number of cards of specified color on the server.
  }
  elseif ($2 == .players) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .players
    .msg $$1 Use: Shows players in current game.
  }
  elseif ($2 == .scores) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .scores
    .msg $$1 Use: Displays the top 10 scores on the current server.
  }
  elseif ($2 == .search) {
    .msg $$1 $v2 
    .msg $$1 Syntax: .search <color> <wildcard>
    .msg $$1 Use: Searches for the wildcard in the card list specified.
  }
}
;------------------------------------------------------------------------------------------------------------
;--------------------------------------------------Shorcuts--------------------------------------------------
;------------------------------------------------------------------------------------------------------------
alias applayerlist {
  var %n = 1
  while (%n < $applayer()) {
    var %pl = %pl $gettok($aget(players),%n,131) $+ $chr(44)
    inc %n
  }
  if (%n = 1) {
    return $gettok($aget(players),%n,131)
  }
  else {
    return $left(%pl,-1) and $gettok($aget(players),%n,131)
  }
}
alias applayer {
  if (!$1) {
    return $numtok($aget(players),131)
  }
  elseif ($1 !isnum) {
    return $findtok($aget(players),$1,131)
  }
  else {
    return $gettok($aget(players),$1,131)
  }
}
alias aget {
  if (!$1) {
    return $hget($aname)
  }
  else {
    return $hget($aname,$1)
  }
}
alias appchan {
  return $readini(apples\appcfg.ini,$network,chan)
}
alias aname {
  return apples. $+ $network
}
alias cname {
  return cards. $+ $network
}
alias rcards {
  return $round($calc($hfind($cname,$$1 $+ *,0,w) / $hget($cname,tot $+ $$1)),2)
}
alias isappmod {
  return $istok($appop($network,mods),$$1,44)
}
alias appop {
  return $readini(apples\appcfg.ini,$$1,$$2)
}
menu channel,status,@applog {
  Apples  
  .\Apples\: /run explorer.exe $mircdir $+ apples\
  .Config: /dialog -m appcfg appcfg
  .AppOff: /appoff
  .Bug List: /run notepad++.exe apples\newbugs.txt
}
;-----------------------------------------------------------------------------------------------------------
;------------------------------------CONFIG DIALOGS---------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------


;-------------------------------------------appcfg
dialog appcfg {
  title "Apples Options"
  size -1 -1 463 264
  option pixels notheme
  list 1, 19 27 106 134 
  edit "", 2, 202 37 100 20
  edit "", 3, 265 65 37 21
  edit "", 4, 265 92 37 21
  edit "", 5, 265 121 37 21
  button "Edit", 6, 39 170 65 25
  button "Mod List", 7, 359 119 65 25
  button "Deafaults", 8, 264 160 65 25
  button "Ok", 10, 182 213 65 25
  box "Server", 20, 9 11 125 195
  text "Channel:", 24, 139 39 60 17
  text "Round Time:", 25, 139 67 60 17
  text "Join Time:", 26, 139 95 60 17
  text "Drop time:", 27, 139 123 60 17
  check "Connect on start", 9, 319 39 115 17
  check "Allow extra cards", 11, 319 67 115 17
  check "Mods only", 12, 338 94 95 17
  box "Settings", 13, 132 23 318 169
}
on *:dialog:appcfg:init:0: {
  apcfgref
}
on *:dialog:appcfg:sclick:*: {
  var %s = $did(appcfg,1,$did(appcfg,1).sel)
  if ($did == 1) {
    did -e appcfg 2-5,7-9,11
    did -b appcfg 12
    did -u appcfg 9,11,12
    if ($appop(%s,chan))  did -o appcfg 2 1 $v1 
    if ($appop(%s,rtime)) did -o appcfg 3 1 $v1 
    if ($appop(%s,jtime)) did -o appcfg 4 1 $v1
    if ($appop(%s,dtime)) did -o appcfg 5 1 $v1
    if ($appop(%s,aconn)) did -c appcfg 9
    if ($appop(%s,extcrd)) did -c appcfg 11
    if ($did(appcfg,11).state) did -e appcfg 12
    if ($appop(%s,modadd)) did -c appcfg 12
  }
  elseif ($did == 6) {
    dialog -ma appsrvr appsrvr
  }
  elseif ($did == 7) {
    if ($did(appcfg,1).sel) {
      dialog -ma appmods appmods
    }
  }
  elseif ($did == 8) {
    did -o appcfg 2 1 #Apples
    did -o appcfg 3 1 60
    did -o appcfg 4 1 60
    did -o appcfg 5 1 30
    did -u appcfg 9,11,12
    did -b appcfg 12
    writeini apples\appcfg.ini %s chan #Apples
    writeini apples\appcfg.ini %s rtime 60
    writeini apples\appcfg.ini %s jtime 60
    writeini apples\appcfg.ini %s dtime 30
    writeini apples\appcfg.ini %s aconn 0
    writeini apples\appcfg.ini %s extcrd 0
    writeini apples\appcfg.ini %s modadd 0
  }
  elseif ($did == 9) {
    if ($did(appcfg,1).sel) {
      var %s = $did(appcfg,1,$did(appcfg,1).sel)
      writeini apples\appcfg.ini %s aconn $iif($did(appcfg,9).state,1,0)
    }
  }
  elseif ($did == 11) {
    if ($did(appcfg,1).sel) {
      var %s = $did(appcfg,1,$did(appcfg,1).sel)
      writeini apples\appcfg.ini %s extcrd $iif($did(appcfg,11).state,1,0)
      if ($did(appcfg,11).state) {
        did -e appcfg 12
      }
      else {
        did -b appcfg 12
      }
    }
  }
  elseif ($did == 12) {
    if ($did(appcfg,1).sel) {
      var %s = $did(appcfg,1,$did(appcfg,1).sel)
      writeini apples\appcfg.ini %s modadd $iif($did(appcfg,12).state,1,0)
    }
  }
  elseif ($did == 10) {
    dialog -x appcfg
  }
}
on *:dialog:appcfg:edit:*: {
  var %s = $did(appcfg,1,$did(appcfg,1).sel)
  if ($did == 2) writeini apples\appcfg.ini %s chan $did(appcfg,$v1)
  if ($did == 3) writeini apples\appcfg.ini %s rtime $did(appcfg,$v1)
  if ($did == 4) writeini apples\appcfg.ini %s jtime $did(appcfg,$v1)
  if ($did == 5) writeini apples\appcfg.ini %s dtime $did(appcfg,$v1)
}
alias apcfgref {
  did -r appcfg 1-5   
  var %dn = 1
  while (%dn <= $ini(apples\appcfg.ini,0)) {
    did -a appcfg 1 $ini(apples\appcfg.ini,%dn)
    inc %dn
  }
  did -u appcfg 9,11,12
  did -b appcfg 2-5,7-9,11,12
}
;----------------------------------------------------------appsrvr
dialog appsrvr {
  title "Apple Servers"
  size -1 -1 272 246
  option pixels notheme
  list 1, 20 25 100 156
  list 2, 154 25 100 156
  button "Add", 3, 38 175 65 25
  button "Remove", 4, 172 177 65 25
  button "OK", 5, 105 210 65 25
  box "All Servers", 6, 16 11 107 166
  box "Apple Servers", 7, 150 11 107 166
}
on *:dialog:appsrvr:init:0: {
  appsrvrref
}
on *:dialog:appsrvr:sclick:*: {
  if ($did == 5) {
    apcfgref
    dialog -x appsrvr
  }
  elseif ($did == 3) {
    var %sname = $did(appsrvr,1,$did(appsrvr,1).sel)
    writeini apples\appcfg.ini %sname chan #Apples
    writeini apples\appcfg.ini %sname rtime 60
    writeini apples\appcfg.ini %sname jtime 60
    writeini apples\appcfg.ini %sname dtime 30
    writeini apples\appcfg.ini %sname aconn 0
    writeini apples\appcfg.ini %sname extcrd 0
    writeini apples\appcfg.ini %sname modadd 0
    appsrvrref
  }
  elseif ($did == 4) {
    remini apples\appcfg.ini $did(appsrvr,2,$did(appsrvr,2).sel)
    appsrvrref
  }
}
alias appsrvrref {
  did -r appsrvr 1-2 
  var %sn = 1
  while (%sn <= $server(0)) {
    if (!$ini(apples\appcfg.ini,$server(%sn).group)) {
      did -a appsrvr 1 $server(%sn).group
    }
    inc %sn
  }
  var %asn = 1
  while (%asn <= $ini(apples\appcfg.ini,0)) {
    did -a appsrvr 2 $ini(apples\appcfg.ini,%asn)
    inc %asn  
  }
  did -u appsrvr 1-2
}
;--------------------------------------------------appmods
dialog appmods {
  title "Apple Mods"
  size -1 -1 129 323
  option pixels notheme
  edit "", 1, 15 38 100 20
  button "Add", 2, 33 61 65 25, default
  list 3, 15 89 100 150
  button "Remove", 4, 33 242 65 25
  text "", 5, 14 11 100 17, center
  button "Done", 6, 17 274 94 34, ok
}
on *:dialog:appmods:init:0: {
  appmodsref
}
on *:dialog:appmods:sclick:*: {
  if ($did == 2) {
    if ($did(appmods,1)) { 
      writeini apples\appcfg.ini $did(appmods,5) mods $addtok($appop($did(appmods,5),mods),$did(appmods,1),44)
      appmodsref
    }
  }
  elseif ($did == 4) {
    if ($did(appmods,3).lines > 1) {
      writeini apples\appcfg.ini $did(appmods,5) mods $remtok($appop($did(appmods,5),mods),$did(appmods,3,$did(appmods,3).sel),1,44)
      appmodsref
    }
    elseif ($did(appmods,3).lines = 1) {
      remini apples\appcfg.ini $did(appmods,5) mods
      appmodsref
    }
  }
}
alias appmodsref {
  did -r appmods 1,3,5
  did -a appmods 5 $did(appcfg,1,$did(appcfg,1).sel)
  var %mn = 1
  while (%mn <= $appmods($did(appmods,5),0)) {
    did -a appmods 3 $appmods($did(appmods,5),%mn)
    inc %mn
  }
}
alias appmods {
  if ($$2 == 0) return $numtok($readini(apples\appcfg.ini,$$1,mods),44)
  else return $gettok($readini(apples\appcfg.ini,$$1,mods),$$2,44)
}
