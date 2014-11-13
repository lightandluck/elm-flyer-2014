module Update where

import List
import SFX (SFX)
import Object (..)
import Playground (..)
import Playground.Input (..)
import Keyboard.Keys as Keys
import State (..)
import Enemy.Generator (nextWave)
import Debug

import Player
import Physics

update : RealWorld -> Input -> State -> State
update rw input state = 
    let state' = Debug.watch "State" state in
    case input of
      Passive t ->
          let fps = Debug.watch "FPS" (1000 / t)
              state' = (cleanUp << Physics.physics t) { state | time <- state.time + (t/20) }
              state'' = checkWave state'
          in state''
      otherwise ->  
        let state' = handleFire input state
            player' = Player.move state'.player input
        in { state' | player <- player' }

checkWave : State -> State
checkWave state =
    if | (not << List.isEmpty) state.enemies -> state
       | otherwise ->
           let (enemies', generator') = nextWave state.generator
           in { state | 
                enemies <- enemies'
              , generator <- generator'
              }


handleFire : Input -> State -> State
handleFire input state = 
    case input of
      Tap k -> if | k `Keys.equals` Keys.space -> 
                    let ps = Player.fire state.player
                        -- This is super annoying...
                        -- It would be much beter if you could 
                        -- do { player.traits | modifiers }
                        -- but the parser can't figure it out
                        player = state.player
                        traits = player.traits
                        cooldown' = if isEmpty ps 
                                    then traits.cooldown
                                    else (head ps).traits.cooldown
                        traits' = { traits | cooldown <- cooldown' }
                        player' = { player | traits <- traits' }
                    in { state | projectiles <- ps ++ state.projectiles,
                                 player <- player' }
                  | otherwise -> state
      otherwise -> state


cleanUp : State -> State
cleanUp state =
    let (pps, newSFX) = cleanObjects state.projectiles
        (objs, newSFX') = cleanObjects state.enemies
        sfxs' = filter cleanSFX (newSFX ++ newSFX' ++ state.sfxs)
    in {state | projectiles <- pps, enemies <- objs, sfxs <- sfxs'}

cleanSFX : SFX -> Bool
cleanSFX { time, duration } = time < duration

cleanObjects : [Object a b] -> ([Object a b], [SFX])
cleanObjects = cleanObjects' ([], [])

cleanObjects' : ([Object a b], [SFX]) -> [Object a b] -> ([Object a b], [SFX])
cleanObjects' (acc_os, sfxs) os =
    case os of
      [] -> (acc_os, sfxs)
      (o::os') -> if | o.traits.destroyed -> 
                         let sfx = o.destroyedSFX o.traits
                         in cleanObjects' (acc_os, sfx::sfxs) os'
                     | otherwise -> cleanObjects' (o::acc_os, sfxs) os'
         