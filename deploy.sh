#/bin/bash
#set -e

echo original parameters=[$*]

SCRIPT_NAME=$(basename "$0")

DEPLOY_TO=$(docker context show);
DEPLOY_FROM='local';
PROJECT="command-server";
VOLUME="";
BRANCH="main";
NO_CACHE="";
INCREMENT=0;
CLEAN=false;
SETTING='';
SETTING_ENV='';

OPTIONS_SHORT="f:t:p:v:b:i:s:"
OPTIONS_LONG="from:,to:,project:,volume:,branch:,increment:,setting:,no-cache,clean,help"


if ! ARGS=$(getopt -o $OPTIONS_SHORT --long $OPTIONS_LONG -n "$0" -- "$@"); then
  echo "Terminating..."
  echo -e "Usage: ./$SCRIPT_NAME [options]\n"
  exit 1
fi

eval set -- "${ARGS}"


while true;
do
    case $1 in
        -p|--project)
            PROJECT=$2;
            shift 2
            ;;
        -f|--from)
            echo "DEPLOY_FROM: $2;"
            DEPLOY_FROM=$2;
            shift 2
            ;;
        -t|--to)
            echo "DEPLOY_TO: $2;"
            DEPLOY_TO=$2;
            shift 2
            ;;
        -v|--volume)
            echo "volume: $2;"
            VOLUME=$2;
            shift 2
            ;;
        -b|--branch)
            echo "branch: $2;"
            BRANCH=$2;
            shift 2
            ;;
        -i|--increment)
          echo "increment: $2;"
          INCREMENT=`expr "$2" + 0`;
          shift 2
          ;;
        -s|--setting)
          echo "setting.py: $2;"
          SETTING=$2;
          shift 2
          ;;
        --no-cache)
            NO_CACHE='--no-cache';
            shift 1
            ;;
        --clean)
          echo "clean: $2;"
          CLEAN=true;
          shift 1
          ;;
        --)
          shift 1
          break
          ;;
        ?)
          echo "there is unrecognized parameter."
          exit 1
          ;;
    esac
done

echo "PROJECT: $PROJECT"
echo "DEPLOY_TO: $DEPLOY_TO"
echo "VOLUME: $VOLUME"
echo "SETTING: $SETTING"
echo "BRANCH: $BRANCH"
echo "INCREMENT": $INCREMENT

base_dir=$(cd "$(dirname "$0")";pwd);
echo "base_dir is $base_dir"

if [ "$DEPLOY_FROM" = 'local' ];
then
  BUILD_PATH=$base_dir
elif [ "$DEPLOY_FROM" = 'git' ];
then
  tmp_path="/tmp/build-$PROJECT"
  echo "rm -rf $tmp_path && mkdir -p $tmp_path && cd $tmp_path"
  rm -rf $tmp_path && mkdir -p $tmp_path && cd $tmp_path
  echo "git clone -b $BRANCH git@github.com:cone387/command-server.git"
  git clone -b $BRANCH git@github.com:cone387/command-server.git
  cd ReportTaskSystem;
  BUILD_PATH="$tmp_path/$PROJECT"
else
  echo "deploy from $DEPLOY_FROM is not supported"
  exit 1
fi

echo "BUILD_PATH is $BUILD_PATH"

if [ "$DEPLOY_TO" = "pypi" ];
then
  echo "start to deploy to pypi"
  if ! type twine >/dev/null 2>&1; then
    echo 'twine does not exists, start to install twine'
    pip install twine
  fi
  rm -rf ./dist/*
  python setup.py sdist
  twine upload dist/*
  exit 0
fi

deploy_context=$DEPLOY_TO
context="$deploy_context"

echo "current context is $context, deploy context is $deploy_context"
if [ "$context" != "$deploy_context" ]
then
  docker context use $deploy_context
  echo "change context from $context to $deploy_context"
fi


if [ $INCREMENT -eq 0 ];
then
  CLEAN=true;
  INCREMENT=1;
fi

if [ $CLEAN = true ];
then
  cid=`docker ps -a | grep $PROJECT | awk '{print $1}'`
  for c in $cid
  do
      docker stop $c
      docker rm $c
  done
fi

for((i=0;i<$INCREMENT;i++)) ; do
  NOW=`date "+%Y-%m-%d-%H-%M-%S"`
  CURRENT_PROJECT=$PROJECT-$NOW
  echo "docker build $NO_CACHE -t $CURRENT_PROJECT -f $BUILD_PATH/Dockerfile $BUILD_PATH"
  docker build $NO_CACHE -t $PROJECT -f $BUILD_PATH/Dockerfile $BUILD_PATH
  echo "docker run -d -p 8002:8000 --name $CURRENT_PROJECT $PROJECT --log-opt max-size=100m"
  docker run -d -p 8002:8000 --name $CURRENT_PROJECT $PROJECT --log-opt max-size=100m
  sleep 1
done

echo "deploy finished."


if [ "$context" != "$deploy_context" ]
then
  docker context use $context
  echo "reset context from $deploy_context to $context"
fi