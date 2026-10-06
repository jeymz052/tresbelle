begin;
insert into public.locations(id,name,address,city,province,postal_code,phone,email) values
('10000000-0000-0000-0000-000000000001','Tres Belle Aesthetic Clinic','Plaza Esperanza, Poblacion','Santa Maria','Bulacan','3022','09608179045','rnlrskininnovationinc@gmail.com');
insert into public.service_categories(id,name,slug,sort_order) values
('30000000-0000-0000-0000-000000000001','Aesthetic Care','aesthetic-care',1),
('30000000-0000-0000-0000-000000000002','Facial Care','facial-care',2),
('30000000-0000-0000-0000-000000000003','IV Wellness','iv-wellness',3);
create temp table seed(category uuid,name text,slug text,description text,duration int,price numeric,promo numeric,unit text);
insert into seed values
('30000000-0000-0000-0000-000000000001','BelleTox','belletox','Refresh, smooth, natural.',30,195,null,'unit'),
('30000000-0000-0000-0000-000000000001','Fat Dissolving Injection','fat-dissolving','Refine, contour, reveal.',45,995,null,'session'),
('30000000-0000-0000-0000-000000000001','Hair Reducer','hair-reducer','Smoother skin, longer confidence.',45,1495,null,'session'),
('30000000-0000-0000-0000-000000000001','Laser Treatment','laser-treatment','Clearer skin, brighter tomorrows.',45,1495,null,'session'),
('30000000-0000-0000-0000-000000000001','Peels','peels','Renew, reveal, glow.',45,2495,null,'session'),
('30000000-0000-0000-0000-000000000001','Microneedling','microneedling','Smoother texture, firmer skin.',60,2995,null,'session'),
('30000000-0000-0000-0000-000000000002','Très Belle Signature','signature-facial','Deep cleanse, refresh, reveal.',60,1195,795,'session'),
('30000000-0000-0000-0000-000000000002','Crystal Aqua Belle','crystal-aqua-belle','Hydrates, purifies, illuminates.',75,1895,995,'session'),
('30000000-0000-0000-0000-000000000002','Velvet Renewal','velvet-renewal','Advanced hydration.',90,2295,1395,'session'),
('30000000-0000-0000-0000-000000000002','Acne Clarity','acne-clarity','Controls oil and restores balance.',75,2595,1995,'session'),
('30000000-0000-0000-0000-000000000003','Pearl Push','pearl-push','Radiant, even-toned skin.',30,1495,995,'session'),
('30000000-0000-0000-0000-000000000003','Signature Push','signature-push','Beauty and immunity boost.',30,1995,1495,'session'),
('30000000-0000-0000-0000-000000000003','Reset Drip','reset-drip','Detox and recharge.',60,2495,1195,'session'),
('30000000-0000-0000-0000-000000000003','Pearl Drip','pearl-drip','Whitening and radiance.',60,2495,1295,'session'),
('30000000-0000-0000-0000-000000000003','Glowing Drip','glowing-drip','Nourishing rejuvenation.',60,3295,1595,'session');
insert into public.services(category_id,name,slug,description,duration_minutes) select category,name,slug,description,duration from seed;
insert into public.service_prices(service_id,amount,promotional_amount,unit,starting_price) select s.id,x.price,x.promo,x.unit,x.promo is null from public.services s join seed x using(slug);
commit;
