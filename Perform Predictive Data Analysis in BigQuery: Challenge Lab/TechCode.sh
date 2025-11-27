#!/bin/bash

# ======================
# Color Variables
# ======================
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
TEAL_TEXT=$'\033[38;5;50m'
PURPLE_TEXT=$'\033[0;35m'
GOLD_TEXT=$'\033[0;33m'
LIME_TEXT=$'\033[0;92m'
MAROON_TEXT=$'\033[0;91m'
NAVY_TEXT=$'\033[0;94m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
BLINK_TEXT=$'\033[5m'
NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
REVERSE_TEXT=$'\033[7m'

clear


echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}      SUBSCRIBE TECH & CODE - INITIATING EXECUTION...             ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==================================================================${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}Enter required variables below:${RESET_FORMAT}"

read -p "Enter EVENT value: ${YELLOW_TEXT}${BOLD_TEXT}" EVENT; echo -e "${RESET_FORMAT}"
read -p "Enter TABLE value: ${YELLOW_TEXT}${BOLD_TEXT}" TABLE; echo -e "${RESET_FORMAT}"
read -p "Enter VALUE_X1: ${YELLOW_TEXT}${BOLD_TEXT}" VALUE_X1; echo -e "${RESET_FORMAT}"
read -p "Enter VALUE_Y1: ${YELLOW_TEXT}${BOLD_TEXT}" VALUE_Y1; echo -e "${RESET_FORMAT}"
read -p "Enter VALUE_X2: ${YELLOW_TEXT}${BOLD_TEXT}" VALUE_X2; echo -e "${RESET_FORMAT}"
read -p "Enter VALUE_Y2: ${YELLOW_TEXT}${BOLD_TEXT}" VALUE_Y2; echo -e "${RESET_FORMAT}"
read -p "Enter FUNC_1: ${YELLOW_TEXT}${BOLD_TEXT}" FUNC_1; echo -e "${RESET_FORMAT}"
read -p "Enter FUNC_2: ${YELLOW_TEXT}${BOLD_TEXT}" FUNC_2; echo -e "${RESET_FORMAT}"
read -p "Enter MODEL name: ${YELLOW_TEXT}${BOLD_TEXT}" MODEL; echo -e "${RESET_FORMAT}"

bq load --source_format=NEWLINE_DELIMITED_JSON --autodetect $DEVSHELL_PROJECT_ID:soccer.$EVENT gs://spls/bq-soccer-analytics/events.json
bq load --source_format=CSV --autodetect $DEVSHELL_PROJECT_ID:soccer.$TABLE gs://spls/bq-soccer-analytics/tags2name.csv
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.competitions gs://spls/bq-soccer-analytics/competitions.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.matches gs://spls/bq-soccer-analytics/matches.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.teams gs://spls/bq-soccer-analytics/teams.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.players gs://spls/bq-soccer-analytics/players.json
bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $DEVSHELL_PROJECT_ID:soccer.events gs://spls/bq-soccer-analytics/events.json


bq query --use_legacy_sql=false "
SELECT
playerId,
(Players.firstName || ' ' || Players.lastName) AS playerName,
COUNT(id) AS numPKAtt,
SUM(IF(101 IN UNNEST(tags.id), 1, 0)) AS numPKGoals,
SAFE_DIVIDE(
SUM(IF(101 IN UNNEST(tags.id), 1, 0)),
COUNT(id)
) AS PKSuccessRate
FROM
\`soccer.$EVENT\` Events
LEFT JOIN
\`soccer.players\` Players ON Events.playerId = Players.wyId
WHERE
eventName = 'Free Kick' AND
subEventName = 'Penalty'
GROUP BY
playerId, playerName
HAVING
numPkAtt >= 5
ORDER BY
PKSuccessRate DESC, numPKAtt DESC
"

bq query --use_legacy_sql=false "
WITH Shots AS (
SELECT *,
(101 IN UNNEST(tags.id)) AS isGoal,
SQRT(
POW((100 - positions[ORDINAL(1)].x) * $VALUE_X1/$VALUE_Y1, 2) +
POW((60 - positions[ORDINAL(1)].y) * $VALUE_X2/$VALUE_Y2, 2)
) AS shotDistance
FROM \`soccer.$EVENT\`
WHERE eventName = 'Shot'
OR (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
)
SELECT
ROUND(shotDistance, 0) AS ShotDistRound0,
COUNT(*) AS numShots,
SUM(IF(isGoal, 1, 0)) AS numGoals,
AVG(IF(isGoal, 1, 0)) AS goalPct
FROM Shots
WHERE shotDistance <= 50
GROUP BY ShotDistRound0
ORDER BY ShotDistRound0
"

bq query --use_legacy_sql=false "
CREATE MODEL \`$MODEL\`
OPTIONS(model_type='LOGISTIC_REG', input_label_cols=['isGoal']) AS
SELECT
Events.subEventName AS shotType,
(101 IN UNNEST(Events.tags.id)) AS isGoal,
\`$FUNC_1\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotDistance,
\`$FUNC_2\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotAngle
FROM \`soccer.$EVENT\` Events
LEFT JOIN \`soccer.matches\` Matches
ON Events.matchId = Matches.wyId
LEFT JOIN \`soccer.competitions\` Competitions
ON Matches.competitionId = Competitions.wyId
WHERE Competitions.name != 'World Cup'
AND (
 eventName='Shot'
 OR (eventName='Free Kick' AND subEventName IN ('Free kick shot','Penalty'))
)
AND \`$FUNC_2\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) IS NOT NULL
;
"

bq query --use_legacy_sql=false "
SELECT
predicted_isGoal_probs[ORDINAL(1)].prob AS predictedGoalProb,
* EXCEPT (predicted_isGoal, predicted_isGoal_probs)
FROM ML.PREDICT(
MODEL \`$MODEL\`,
(
 SELECT
   Events.playerId,
   (Players.firstName || ' ' || Players.lastName) AS playerName,
   Teams.name AS teamName,
   CAST(Matches.dateutc AS DATE) AS matchDate,
   Matches.label AS match,
   CAST((CASE WHEN Events.matchPeriod='1H' THEN 0
     WHEN Events.matchPeriod='2H' THEN 45
     WHEN Events.matchPeriod='E1' THEN 90
     WHEN Events.matchPeriod='E2' THEN 105
     ELSE 120 END)
     + CEILING(Events.eventSec/60) AS INT64) AS matchMinute,
   Events.subEventName AS shotType,
   (101 IN UNNEST(Events.tags.id)) AS isGoal,
   \`soccer.$FUNC_1\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotDistance,
   \`soccer.$FUNC_2\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotAngle
 FROM \`soccer.$EVENT\` Events
 LEFT JOIN \`soccer.matches\` Matches ON Events.matchId = Matches.wyId
 LEFT JOIN \`soccer.competitions\` Competitions ON Matches.competitionId = Competitions.wyId
 LEFT JOIN \`soccer.players\` Players ON Events.playerId = Players.wyId
 LEFT JOIN \`soccer.teams\` Teams ON Events.teamId = Teams.wyId
 WHERE Competitions.name='World Cup'
 AND (
   eventName='Shot'
   OR (eventName='Free Kick' AND subEventName='Free kick shot')
 )
 AND (101 IN UNNEST(Events.tags.id))
)
)
ORDER BY predictedGoalProb
"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}              LAB COMPLETED SUCCESSFULLY!              ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=======================================================${RESET_FORMAT}"
echo
echo "${RED_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@TechCode9${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}Don't forget to Like, Share and Subscribe for more Videos${RESET_FORMAT}"
