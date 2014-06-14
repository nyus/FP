//
//  Log.h
//  FastPost
//
//  Created by Sihang Huang on 1/9/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

Jan 9
added date label on status cell

//adjusted status cell layout based on new design
pull user profile picture to status cell
added spinner when pulling image on status cell
dwindles, followers, following
no revive if the options is turned off
cell size dynamic adjustment

-----
username case insensitive and unique

user can have "usersIFollow" "usersFollowMe" and "usersMutualFollow"
"usersIFollow" holds users that I follow and they allow me to follow, but they do not follow me back
"usersFollowMe" holds users that follow me and i allow them to follow, but i do not follow them back
"usersMutualFollow" holds users that i follow, and they also follow me back