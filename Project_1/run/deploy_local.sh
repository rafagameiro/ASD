nNodes=$1
shift

echo "Killing everything"
sudo docker kill $(sudo docker ps -q) 
wait
sudo docker swarm leave -f

echo "Creating network"
sudo docker swarm init --advertise-addr 127.0.0.1
sudo docker swarm join-token manager -q
sudo docker network create -d overlay --attachable --subnet 172.10.0.0/16 leitaonet

echo "Rebuilding image"
sudo docker build --rm -t asdproj .
wait

mkdir ./logs

echo "Launching containers"
for i in $(seq 00 $(($nNodes - 1))); do
  ii=$(printf "%.2d" $i)
  echo -n "$ii - "
  
  sudo docker run -d -t --rm \
    --privileged --cap-add=ALL \
    --mount type=bind,source="$(pwd)/logs",target=/code/logs \
    --net leitaonet --ip 172.10.10.${i} -h root-${ii} --name root-${ii} \
    asdproj ${i}
done

sleep 1

echo "Executing java"

printf "%.2d.. " 0
user=$(id -u):$(id -g)
sudo docker exec -d root-00 ./start.sh 0 $user contact=172.10.10.0:6000 "$@" #não pode ser root-00 pois ainda não foi executado

sleep 1

for i in $(seq 01 $(($nNodes - 1))); do
  ii=$(printf "%.2d" $i)
  echo -n "$ii.. "
  if [ $((($i + 1) % 10)) -eq 0 ]; then
    echo ""
  fi 
  sudo docker exec -d root-${ii} ./start.sh $i $user contact=root-00:6000 "$@" 
  sleep 1
done
echo ""
