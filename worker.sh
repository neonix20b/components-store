#!/usr/bin/env bash

rsync -auzvc tmp/search srv-cob4jaa1hbls73ambvrg@ssh.frankfurt.render.com:tmp/
#rsync -auzvc srv-cob4jaa1hbls73ambvrg@ssh.frankfurt.render.com:tmp/search tmp/

for i in {1..5}
do
   echo "Welcome $i times"
   # [30, 32, 36, 38, 40, 42, 43, 44, 45, 46, [47, 48, 49, 50, 51, 52].each{|i| BaseRoutine.loadProductsFor taxon: Spree::Taxon.find(i), in_threads: 2 }
   # rails runner "BaseRoutine.loadProductsFor taxon: Spree::Taxon.find(38)"
   # BaseRoutine.cleanProperties
   # BaseRoutine.updateDescriptionsAsync limit: 5_000, offset: 0
   # BaseRoutine.batchProcess id: "batch_ropv1muFCkKFwrr7cjn5nu0G"
   # bundle exec rake sitemap:refresh:no_ping
   # bundle exec rake feeds:yandex
   # bundle exec rake feeds:google
   # YandexTurbo.generate page: 10
done
