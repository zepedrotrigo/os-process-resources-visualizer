/**
 *  \file semSharedWatcher.c (implementation file)
 *
 *  \brief Problem name: SoccerGame
 *
 *  Synchronization based on semaphores and shared memory.
 *  Implementation with SVIPC.
 *
 *  Definition of the operations carried out by the goalie:
 *     \li arriving
 *     \li goalieConstituteTeam
 *     \li waitReferee
 *     \li playUntilEnd
 *
 *  \author Nuno Lau - January 2021
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <string.h>
#include <math.h>
#include <assert.h>

#include "probConst.h"
#include "probDataStruct.h"
#include "logging.h"
#include "sharedDataSync.h"
#include "semaphore.h"
#include "sharedMemory.h"

/** \brief logging file name */
static char nFic[51];

/** \brief shared memory block access identifier */
static int shmid;

/** \brief semaphore set access identifier */
static int semgid;

/** \brief pointer to shared memory region */
static SHARED_DATA *sh;

/** \brief goalie takes some time to arrive */
static void arrive (int id);

/** \brief goalie constitutes team */
static int goalieConstituteTeam (int id);

/** \brief goalie waits for referee to start match */
static void waitReferee(int id, int team);

/** \brief goalie waits for referee to end match */
static void playUntilEnd(int id, int team);

/**
 *  \brief Main program.
 *
 *  Its role is to generate the life cycle of one of intervening entities in the problem: the goalie.
 */
int main (int argc, char *argv[])
{
    int key;                                            /*access key to shared memory and semaphore set */
    char *tinp;                                                       /* numerical parameters test flag */
    int n, team;

    /* validation of command line parameters */
    if (argc != 4) { 
        freopen ("error_GL", "a", stderr);
        fprintf (stderr, "Number of parameters is incorrect!\n");
        return EXIT_FAILURE;
    }
    
    /* get goalie id - argv[1]*/
    n = (unsigned int) strtol (argv[1], &tinp, 0);
    if ((*tinp != '\0') || (n >= NUMGOALIES )) { 
        fprintf (stderr, "Goalie process identification is wrong!\n");
        return EXIT_FAILURE;
    }

    /* get logfile name - argv[2]*/
    strcpy (nFic, argv[2]);

    /* redirect stderr to error file  - argv[3]*/
    freopen (argv[3], "w", stderr);
    setbuf(stderr,NULL);

    /* getting key value */
    if ((key = ftok (".", 'a')) == -1) {
        perror ("error on generating the key");
        exit (EXIT_FAILURE);
    }

    /* connection to the semaphore set and the shared memory region and mapping the shared region onto the
       process address space */
    if ((semgid = semConnect (key)) == -1) { 
        perror ("error on connecting to the semaphore set");
        return EXIT_FAILURE;
    }
    if ((shmid = shmemConnect (key)) == -1) { 
        perror ("error on connecting to the shared memory region");
        return EXIT_FAILURE;
    }
    if (shmemAttach (shmid, (void **) &sh) == -1) { 
        perror ("error on mapping the shared region on the process address space");
        return EXIT_FAILURE;
    }

    /* initialize random generator */
    srandom ((unsigned int) getpid ());              

    /* simulation of the life cycle of the goalie */
    arrive(n);
    if((team = goalieConstituteTeam(n))!=0) {
        waitReferee(n, team);
        playUntilEnd(n, team);
    }

    /* unmapping the shared region off the process address space */
    if (shmemDettach (sh) == -1) {
        perror ("error on unmapping the shared region off the process address space");
        return EXIT_FAILURE;;
    }

    return EXIT_SUCCESS;
}

/**
 *  \brief goalie takes some time to arrive
 *
 *  Goalie updates state and takes some time to arrive
 *  The internal state should be saved.
 *
 */
static void arrive(int id)
{    
    if (semDown (semgid, sh->mutex) == -1)  {                                                     /* enter critical region */
        perror ("error on the up operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    /* TODO: insert your code here */
    sh->fSt.st.goalieStat[id] = ARRIVING;
    saveState(nFic, &sh->fSt);

    if (semUp (semgid, sh->mutex) == -1) {                                                         /* exit critical region */
        perror ("error on the down operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    usleep((200.0*random())/(RAND_MAX+1.0)+60.0);
}

/**
 *  \brief goalie constitutes team
 *
 *  If goalie is late, it updates state and leaves.
 *  If there are enough free players to form a team, goalie forms team allowing team members to 
 *  proceed and waiting for them to acknowledge registration.
 *  Otherwise it updates state, waits for the forming teammate to "call" him, saves its team
 *  and acknowledges registration.
 *  The internal state should be saved.
 *
 *  \param id goalie id
 * 
 *  \return id of goalie team (0 for late goalies; 1 for team 1; 2 for team 2)
 *ret = sh->fSt.teamId;
 */
static int goalieConstituteTeam (int id)
{
    int ret = 0;

    if (semDown (semgid, sh->mutex) == -1)  {                                                     /* enter critical region */
        perror ("error on the up operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    /* TODO: insert your code here */
    sh->fSt.goaliesArrived++;

    //se chegou atrasado
    if (sh->fSt.goaliesArrived > 2*NUMTEAMGOALIES) {
        sh->fSt.st.goalieStat[id] = LATE;
        saveState(nFic, &sh->fSt);
    }
    // se nao chegou atrasado
    else {
        sh->fSt.goaliesFree++;
        // Verificar se tem recursos para formar equipa 
        if (sh->fSt.playersFree >= NUMTEAMPLAYERS) {
            sh->fSt.st.goalieStat[id] = FORMING_TEAM;
            saveState(nFic, &sh->fSt);

            //enviar sinal para os players se desbloquearem e atribuirem equipa
            for (int i = 0; i < NUMTEAMPLAYERS; i++) {
                if (semUp(semgid, sh->playersWaitTeam) == -1) {
                    perror("error on the down operation for semaphore access (GL)");
                    exit(EXIT_FAILURE);
                }
                sh->fSt.playersFree--; // 4 players que deixam de estar free
            }
            sh->fSt.goaliesFree--; // o goalie deixa de estar free

            //ficar bloqueado à espera dos jogadores responderem que já têm equipa
            for (int i = 0; i < NUMTEAMPLAYERS; i++) {
                if (semDown (semgid, sh->playerRegistered) == -1) {                                                         /* exit critical region */
                    perror ("error on the down operation for semaphore access (GL)");
                    exit (EXIT_FAILURE);
                }
            }

            //alterar o team id depois da equipa estar formada
            ret = sh->fSt.teamId;
            sh->fSt.teamId = 2;
        }
        else {
            //Não tem recursos para formar equipa então vai ficar à espera
            sh->fSt.st.goalieStat[id] = WAITING_TEAM;
            saveState(nFic, &sh->fSt);

        }
    }
    if (semUp(semgid, sh->mutex) == -1) { /* exit critical region */
        perror("error on the down operation for semaphore access (GL)");
        exit(EXIT_FAILURE);
    }
    /* TODO: insert your code here */
    //Baixar o semáforo goaliesWaitTeam se não chegou atrasado e não forma equipa
    if (sh->fSt.goaliesFree <= 2*NUMTEAMGOALIES && sh->fSt.st.goalieStat[id] != LATE) {
        if (sh->fSt.st.goalieStat[id] == WAITING_TEAM) {   
            //fica bloqueado à espera do constitute team do player
            if (semDown (semgid, sh->goaliesWaitTeam) == -1) {                                                         /* exit critical region */
                perror ("error on the down operation for semaphore access (GL)");
                exit (EXIT_FAILURE);
            }
            //aqui já está desbloqueado e já sabemos o teamID
            ret = sh->fSt.teamId;

            //Responder que já tem equipa ao player que está a formar as equipas
            if (semUp (semgid, sh->playerRegistered) == -1) {                                                         /* exit critical region */
                perror ("error on the down operation for semaphore access (GL)");
                exit (EXIT_FAILURE);
            }
        }
        else { //se não está waiting_team, quer dizer que está waiting_start (está pronto)
            if (semUp (semgid, sh->refereeWaitTeams) == -1) {                                                         /* exit critical region */
                perror ("error on the down operation for semaphore access (GL)");
                exit (EXIT_FAILURE);
            }
        }
    }

    return ret;
}

/**
 *  \brief goalie waits for referee to start match
 *
 *  The goalie updates its state and waits for referee to start match.  
 *  The internal state should be saved.
 *
 *  \param id   goalie id
 *  \param team goalie team
 */
static void waitReferee (int id, int team)
{
    if (semDown (semgid, sh->mutex) == -1)  {                                                     /* enter critical region */
        perror ("error on the up operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    /* TODO: insert your code here */
    //atribuir equipa ao goalie que forma a equipa
    if (team == 1) {
        sh->fSt.st.goalieStat[id] = WAITING_START_1;
    }
    else {
        sh->fSt.st.goalieStat[id] = WAITING_START_2;
    }
    saveState(nFic, &sh->fSt);

    if (semUp (semgid, sh->mutex) == -1) {                                                         /* exit critical region */
        perror ("error on the down operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    /* TODO: insert your code here */
    if (semDown(semgid, sh->playersWaitReferee) == -1)
    { /* exit critical region */
        perror ("error on the down operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }
}

/**
 *  \brief goalie waits for referee to end match
 *
 *  The goalie updates its state and waits for referee to end match.  
 *  The internal state should be saved.
 *
 *  \param id   goalie id
 *  \param team goalie team
 */
static void playUntilEnd (int id, int team)
{
    if (semDown (semgid, sh->mutex) == -1)  {                                                     /* enter critical region */
        perror ("error on the up operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    /* TODO: insert your code here */
    if (team == 1) {
        sh->fSt.st.goalieStat[id] = PLAYING_1;
    } else {
        sh->fSt.st.goalieStat[id] = PLAYING_2;
    }
    saveState(nFic, &sh->fSt);

    if (semUp (semgid, sh->mutex) == -1) {                                                         /* exit critical region */
        perror ("error on the down operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }

    /* TODO: insert your code here */
    if (semDown (semgid, sh->playersWaitEnd) == -1) {                                                         /* exit critical region */
        perror ("error on the down operation for semaphore access (GL)");
        exit (EXIT_FAILURE);
    }
    
}

