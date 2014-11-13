module Update where
import Object (..)
import Playground (..)
import Playground.Input (..)
import Keyboard.Keys as Keys
import State (..)
import Debug

import Player
import Physics

update : RealWorld -> Input -> State -> State
update rw input state = 
    let state' = Debug.watch "State" state in
    case input of
      Passive t ->
          let fps = Debug.watch "FPS" (1000 / t) in
          (cleanUp << Physics.physics t) { state | time <- state.time + (t/20) }
      otherwise ->  
        let state' = handleFire input state
            player' = Player.move state'.player input
        in { state' | player <- player' }


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
    let pps = filter (\p -> not p.traits.destroyed) state.projectiles
        objs = filter (\e -> not e.traits.destroyed) state.enemies
    in {state | projectiles <- pps, enemies <- objs}

