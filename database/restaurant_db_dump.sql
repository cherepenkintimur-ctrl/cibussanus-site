--
-- PostgreSQL database dump
--

\restrict p5IJyfvQv8vAqLLkBtm43FC1hA3jdxmEdZPs0mT01stIGbzLbeuhY5bZPMoPGKq

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.order_items DROP CONSTRAINT IF EXISTS order_items_order_id_fkey;
ALTER TABLE IF EXISTS ONLY public.order_items DROP CONSTRAINT IF EXISTS order_items_dish_id_fkey;
ALTER TABLE IF EXISTS ONLY public.dishes DROP CONSTRAINT IF EXISTS dishes_category_id_fkey;
DROP TRIGGER IF EXISTS trg_order_items_set_total ON public.order_items;
DROP TRIGGER IF EXISTS trg_order_items_recalculate_total ON public.order_items;
DROP INDEX IF EXISTS public.idx_orders_order_date;
DROP INDEX IF EXISTS public.idx_order_items_order_id;
DROP INDEX IF EXISTS public.idx_order_items_dish_id;
DROP INDEX IF EXISTS public.idx_dishes_category_id;
ALTER TABLE IF EXISTS ONLY public.orders DROP CONSTRAINT IF EXISTS orders_pkey;
ALTER TABLE IF EXISTS ONLY public.orders DROP CONSTRAINT IF EXISTS orders_order_number_key;
ALTER TABLE IF EXISTS ONLY public.order_items DROP CONSTRAINT IF EXISTS order_items_pkey;
ALTER TABLE IF EXISTS ONLY public.dishes DROP CONSTRAINT IF EXISTS dishes_pkey;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_pkey;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_name_key;
ALTER TABLE IF EXISTS public.orders ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.order_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.dishes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.categories ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.orders_id_seq;
DROP TABLE IF EXISTS public.orders;
DROP SEQUENCE IF EXISTS public.order_items_id_seq;
DROP TABLE IF EXISTS public.order_items;
DROP SEQUENCE IF EXISTS public.dishes_id_seq;
DROP TABLE IF EXISTS public.dishes;
DROP SEQUENCE IF EXISTS public.categories_id_seq;
DROP TABLE IF EXISTS public.categories;
DROP FUNCTION IF EXISTS public.sync_order_total();
DROP FUNCTION IF EXISTS public.set_order_item_line_total();
DROP FUNCTION IF EXISTS public.recalculate_order_total(p_order_id bigint);
--
-- Name: recalculate_order_total(bigint); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.recalculate_order_total(p_order_id bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE orders
    SET total_amount = COALESCE(
        (
            SELECT ROUND(SUM(line_total)::numeric, 2)
            FROM order_items
            WHERE order_id = p_order_id
        ),
        0
    )
    WHERE id = p_order_id;
END;
$$;


ALTER FUNCTION public.recalculate_order_total(p_order_id bigint) OWNER TO postgres;

--
-- Name: set_order_item_line_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_order_item_line_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.line_total := ROUND((NEW.quantity * NEW.unit_price)::numeric, 2);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_order_item_line_total() OWNER TO postgres;

--
-- Name: sync_order_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sync_order_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM recalculate_order_total(OLD.order_id);
        RETURN OLD;
    ELSE
        PERFORM recalculate_order_total(NEW.order_id);
        RETURN NEW;
    END IF;
END;
$$;


ALTER FUNCTION public.sync_order_total() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_id_seq OWNER TO postgres;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: dishes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dishes (
    id bigint NOT NULL,
    category_id bigint,
    name character varying(150) NOT NULL,
    price numeric(10,2) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT dishes_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.dishes OWNER TO postgres;

--
-- Name: dishes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dishes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dishes_id_seq OWNER TO postgres;

--
-- Name: dishes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dishes_id_seq OWNED BY public.dishes.id;


--
-- Name: order_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_items (
    id bigint NOT NULL,
    order_id bigint NOT NULL,
    dish_id bigint NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    line_total numeric(10,2) DEFAULT 0 NOT NULL,
    CONSTRAINT order_items_line_total_check CHECK ((line_total >= (0)::numeric)),
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT order_items_unit_price_check CHECK ((unit_price >= (0)::numeric))
);


ALTER TABLE public.order_items OWNER TO postgres;

--
-- Name: order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_id_seq OWNER TO postgres;

--
-- Name: order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_items_id_seq OWNED BY public.order_items.id;


--
-- Name: orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orders (
    id bigint NOT NULL,
    order_number character varying(30) NOT NULL,
    order_date timestamp with time zone DEFAULT now() NOT NULL,
    total_amount numeric(10,2) DEFAULT 0 NOT NULL,
    payment_method character varying(30),
    notes text,
    CONSTRAINT orders_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


ALTER TABLE public.orders OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.orders_id_seq OWNER TO postgres;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orders_id_seq OWNED BY public.orders.id;


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: dishes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dishes ALTER COLUMN id SET DEFAULT nextval('public.dishes_id_seq'::regclass);


--
-- Name: order_items id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items ALTER COLUMN id SET DEFAULT nextval('public.order_items_id_seq'::regclass);


--
-- Name: orders id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders ALTER COLUMN id SET DEFAULT nextval('public.orders_id_seq'::regclass);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categories (id, name, description, created_at) FROM stdin;
1	Закуски	Лёгкие блюда для начала трапезы	2026-06-26 07:47:06.185995
2	Супы	Традиционные европейские супы	2026-06-26 07:47:06.185995
3	Горячие блюда	Основные блюда из мяса, птицы и рыбы	2026-06-26 07:47:06.185995
4	Гарниры	Овощи, крупы, картофель	2026-06-26 07:47:06.185995
5	Салаты	Свежие овощные и мясные салаты	2026-06-26 07:47:06.185995
6	Десерты	Сладкие блюда и выпечка	2026-06-26 07:47:06.185995
7	Напитки	Горячие и холодные напитки	2026-06-26 07:47:06.185995
\.


--
-- Data for Name: dishes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dishes (id, category_id, name, price, description, is_active, created_at) FROM stdin;
1	1	Брускетта с томатами	350.00	Поджаренный хлеб с помидорами, чесноком и базиликом	t	2026-06-26 07:47:06.185995
2	1	Карпаччо из говядины	590.00	Тонко нарезанная говядина с пармезаном и рукколой	t	2026-06-26 07:47:06.185995
3	1	Оливки ассорти	280.00	Смесь зелёных и чёрных оливок с травами	t	2026-06-26 07:47:06.185995
4	1	Сырная тарелка	680.00	Ассорти из 4 сортов сыра с мёдом и орехами	t	2026-06-26 07:47:06.185995
5	1	Креветки в чесночном соусе	620.00	Королевские креветки на гриле с чесноком и лимоном	t	2026-06-26 07:47:06.185995
6	2	Томатный суп с базиликом	390.00	Густой суп из спелых томатов с пряностями	t	2026-06-26 07:47:06.185995
7	2	Суп-пюре из тыквы	370.00	Крем-суп из тыквы с имбирём и сливками	t	2026-06-26 07:47:06.185995
8	2	Борщ классический	410.00	Наваристый борщ с говядиной, свеклой и сметаной	t	2026-06-26 07:47:06.185995
9	2	Уха царская	520.00	Рыбный суп из сёмги, судака и креветок	t	2026-06-26 07:47:06.185995
10	2	Грибной крем-суп	390.00	Сушёные белые грибы с картофелем и сливками	t	2026-06-26 07:47:06.185995
11	3	Стейк Рибай	1890.00	Мраморная говядина на гриле с розмарином	t	2026-06-26 07:47:06.185995
12	3	Медальоны из свинины	920.00	Свиная вырезка с грибным соусом	t	2026-06-26 07:47:06.185995
13	3	Курица в сливочном соусе	850.00	Филе курицы со сливками, грибами и зеленью	t	2026-06-26 07:47:06.185995
14	3	Лосось на гриле	1340.00	Филе лосося с лимоном и зеленью	t	2026-06-26 07:47:06.185995
15	3	Паста Карбонара	780.00	Спагетти с беконом, яйцом и пармезаном	t	2026-06-26 07:47:06.185995
16	3	Ризотто с грибами	790.00	Классическое ризотто с белыми грибами и трюфельным маслом	t	2026-06-26 07:47:06.185995
17	3	Рататуй	610.00	Запечённые овощи с прованскими травами	t	2026-06-26 07:47:06.185995
18	3	Телятина по-флорентийски	1650.00	Телячья отбивная с артишоками и сыром	t	2026-06-26 07:47:06.185995
19	4	Картофель фри	290.00	Хрустящий картофель с солью	t	2026-06-26 07:47:06.185995
20	4	Картофельное пюре	250.00	Нежное пюре со сливками	t	2026-06-26 07:47:06.185995
21	4	Рис басмати	240.00	Отварной рассыпчатый рис	t	2026-06-26 07:47:06.185995
22	4	Овощи гриль	330.00	Цукини, баклажаны, перец и лук на гриле	t	2026-06-26 07:47:06.185995
23	4	Спаржа с соусом голландез	480.00	Зелёная спаржа с масляным соусом	t	2026-06-26 07:47:06.185995
24	5	Цезарь с курицей	620.00	Классический салат с куриной грудкой, сухариками и соусом	t	2026-06-26 07:47:06.185995
26	5	Нисуаз	670.00	Салат с тунцом, яйцами, фасолью и анчоусами	t	2026-06-26 07:47:06.185995
27	5	Салат с запечёнными овощами	530.00	Тёплый салат с перцем, цукини, баклажанами и бальзамиком	t	2026-06-26 07:47:06.185995
29	6	Тирамису	490.00	Классический итальянский десерт с маскарпоне и кофе	t	2026-06-26 07:47:06.185995
30	6	Крем-брюле	460.00	Заварной крем с карамельной корочкой	t	2026-06-26 07:47:06.185995
31	6	Шоколадный фондан	520.00	Пирожное с жидкой шоколадной начинкой	t	2026-06-26 07:47:06.185995
32	6	Яблочный штрудель	450.00	Слоёный рулет с яблоками, изюмом и орехами	t	2026-06-26 07:47:06.185995
33	6	Панна-котта	430.00	Ванильный десерт с ягодным соусом	t	2026-06-26 07:47:06.185995
34	7	Капучино	280.00	Кофе с молочной пеной	t	2026-06-26 07:47:06.185995
35	7	Латте	290.00	Кофе с большим количеством молока	t	2026-06-26 07:47:06.185995
36	7	Эспрессо	220.00	Крепкий чёрный кофе	t	2026-06-26 07:47:06.185995
37	7	Зелёный чай	200.00	Китайский зелёный чай	t	2026-06-26 07:47:06.185995
38	7	Чай чёрный	180.00	Индийский чёрный чай	t	2026-06-26 07:47:06.185995
39	7	Лимонад	320.00	Домашний лимонад с мятой и лаймом	t	2026-06-26 07:47:06.185995
40	7	Сок апельсиновый	250.00	Свежевыжатый сок	t	2026-06-26 07:47:06.185995
28	5	Кобб-салат	720.00	Салат с курицей, беконом, авокадо, сыром и яйцом	t	2026-06-26 07:47:06.185995
25	5	Греческий салат	520.00	Салат с томатами, огурцами, фетой, маслинами	t	2026-06-26 07:47:06.185995
41	1	Тартар из лосося	620.00	Свежий лосось с авокадо, каперсами и цитрусовой заправкой	t	2026-06-26 08:15:05.195849
42	1	Брускетта с грибами	380.00	Хрустящий хлеб с шампиньонами, чесноком и трюфельным маслом	t	2026-06-26 08:15:05.195849
43	1	Креветки темпура	590.00	Королевские креветки в лёгком кляре с соусом унаги	t	2026-06-26 08:15:05.195849
44	1	Мидии в белом вине	550.00	Мидии с чесноком, петрушкой и сухим белым вином	t	2026-06-26 08:15:05.195849
45	1	Ассорти из вяленых мяс	680.00	Прошутто, брезаола, салями с маринованными овощами	t	2026-06-26 08:15:05.195849
46	2	Французский луковый суп	450.00	Карамелизованный лук на говяжьем бульоне с гренками и сыром	t	2026-06-26 08:15:05.195849
47	2	Минестроне	390.00	Итальянский суп с бобовыми, пастой и свежими овощами	t	2026-06-26 08:15:05.195849
48	2	Гаспачо	350.00	Холодный суп из томатов, огурцов и болгарского перца	t	2026-06-26 08:15:05.195849
49	2	Суп с фрикадельками	420.00	Куриный бульон с домашними фрикадельками и зеленью	t	2026-06-26 08:15:05.195849
50	3	Паста Болоньезе	680.00	Спагетти с мясным соусом и пармезаном	t	2026-06-26 08:15:05.195849
51	3	Лазанья	790.00	Слоёное блюдо с мясом, бешамелем и томатным соусом	t	2026-06-26 08:15:05.195849
52	3	Куриная грудка с грибами	890.00	Филе курицы с шампиньонами в сливочном соусе	t	2026-06-26 08:15:05.195849
53	3	Утка с апельсиновым соусом	1350.00	Запечённая утиная грудка с глазурью из апельсина	t	2026-06-26 08:15:05.195849
54	3	Ягнёнок с розмарином	1550.00	Нежная корейка ягнёнка с чесноком и розмарином	t	2026-06-26 08:15:05.195849
55	3	Морской окунь на гриле	1280.00	Филе окуня с лимоном и сливочным маслом	t	2026-06-26 08:15:05.195849
56	3	Фаршированные кальмары	950.00	Кальмары с рисовой начинкой и томатным соусом	t	2026-06-26 08:15:05.195849
57	3	Телятина с овощами	1420.00	Тушёная телятина с корнеплодами и красным вином	t	2026-06-26 08:15:05.195849
58	3	Свиная рулька	1100.00	Запечённая свиная голяшка с пивным соусом	t	2026-06-26 08:15:05.195849
59	4	Картофель по-деревенски	280.00	Дольки картофеля с травами и чесноком	t	2026-06-26 08:15:05.195849
60	4	Кускус	240.00	Манная крупа со сливочным маслом	t	2026-06-26 08:15:05.195849
61	4	Полента	260.00	Итальянская кукурузная каша с пармезаном	t	2026-06-26 08:15:05.195849
62	4	Тушёные овощи	300.00	Смесь кабачков, баклажанов, перца и помидоров	t	2026-06-26 08:15:05.195849
63	5	Салат с креветками и авокадо	680.00	Креветки, авокадо, руккола, томаты черри и лёгкий соус	t	2026-06-26 08:15:05.195849
64	5	Салат с курицей и ананасом	550.00	Копчёная курица, ананас, свежий огурец и майонез	t	2026-06-26 08:15:05.195849
65	5	Салат с рукколой и пармезаном	490.00	Руккола, груша, пармезан, кедровые орехи и бальзамик	t	2026-06-26 08:15:05.195849
66	6	Мороженое с ягодами	350.00	Шарики ванильного и клубничного мороженого с сезонными ягодами	t	2026-06-26 08:15:05.195849
67	6	Чизкейк	550.00	Нежный творожный десерт с ягодным соусом	t	2026-06-26 08:15:05.195849
68	6	Панакота с манго	460.00	Классическая пана-котта с манговым пюре	t	2026-06-26 08:15:05.195849
69	6	Яблочный пирог	420.00	Песочный пирог с начинкой из яблок и корицы	t	2026-06-26 08:15:05.195849
70	6	Брауни с орехами	480.00	Шоколадное пирожное с грецким орехом	t	2026-06-26 08:15:05.195849
71	7	Глинтвейн безалкогольный	350.00	Тёплый напиток из виноградного сока с пряностями	t	2026-06-26 08:15:05.195849
72	7	Смузи ягодный	380.00	Смесь замороженных ягод с йогуртом	t	2026-06-26 08:15:05.195849
73	7	Молочный коктейль	300.00	Классический коктейль из молока и мороженого	t	2026-06-26 08:15:05.195849
74	7	Чай с бергамотом	200.00	Чёрный чай с бергамотом (Эрл Грей)	t	2026-06-26 08:15:05.195849
75	7	Какао	250.00	Горячий шоколадный напиток	t	2026-06-26 08:15:05.195849
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_items (id, order_id, dish_id, quantity, unit_price, line_total) FROM stdin;
1	1	2	1	590.00	590.00
2	1	12	1	920.00	920.00
3	1	19	1	290.00	290.00
4	2	1	2	350.00	700.00
5	2	13	1	850.00	850.00
6	2	21	1	240.00	240.00
7	2	34	1	280.00	280.00
8	3	6	1	390.00	390.00
9	3	11	1	1890.00	1890.00
10	3	20	1	250.00	250.00
11	3	30	1	460.00	460.00
12	4	24	1	620.00	620.00
13	4	14	1	1340.00	1340.00
14	4	22	1	330.00	330.00
15	5	4	1	680.00	680.00
16	5	15	1	780.00	780.00
17	5	28	1	720.00	720.00
18	5	39	1	320.00	320.00
19	5	36	1	220.00	220.00
20	6	7	1	370.00	370.00
21	6	16	1	790.00	790.00
22	6	23	1	480.00	480.00
23	7	3	2	280.00	560.00
24	7	18	1	1650.00	1650.00
25	7	29	1	490.00	490.00
26	8	8	1	410.00	410.00
27	8	25	1	520.00	520.00
28	8	17	1	610.00	610.00
29	8	38	1	180.00	180.00
30	9	5	1	620.00	620.00
31	9	26	1	670.00	670.00
32	9	31	1	520.00	520.00
33	10	9	1	520.00	520.00
34	10	27	1	530.00	530.00
35	10	10	1	390.00	390.00
36	10	40	1	250.00	250.00
37	11	41	1	620.00	620.00
38	11	46	1	450.00	450.00
39	11	50	1	680.00	680.00
40	11	59	1	280.00	280.00
41	12	42	1	380.00	380.00
42	12	47	1	390.00	390.00
43	12	63	1	680.00	680.00
44	12	66	1	350.00	350.00
45	13	43	1	590.00	590.00
46	13	48	1	350.00	350.00
47	13	52	1	890.00	890.00
48	13	60	1	240.00	240.00
49	13	67	1	550.00	550.00
50	14	44	1	550.00	550.00
51	14	49	1	420.00	420.00
52	14	53	1	1350.00	1350.00
53	14	64	1	550.00	550.00
54	15	45	1	680.00	680.00
55	15	54	1	1550.00	1550.00
56	15	68	1	460.00	460.00
57	15	71	1	350.00	350.00
58	16	55	1	1280.00	1280.00
59	16	61	1	260.00	260.00
60	16	69	1	420.00	420.00
61	16	72	1	380.00	380.00
62	17	56	1	950.00	950.00
63	17	62	1	300.00	300.00
64	17	70	1	480.00	480.00
65	17	73	1	300.00	300.00
66	18	57	1	1420.00	1420.00
67	18	65	1	490.00	490.00
68	18	74	1	200.00	200.00
69	18	35	1	290.00	290.00
70	19	58	1	1100.00	1100.00
71	19	75	1	250.00	250.00
72	19	37	1	200.00	200.00
73	19	32	1	450.00	450.00
74	20	11	1	1890.00	1890.00
75	20	14	1	1340.00	1340.00
76	20	24	1	620.00	620.00
77	20	19	2	290.00	580.00
78	20	34	2	280.00	560.00
79	21	2	1	590.00	590.00
80	21	15	1	780.00	780.00
81	21	20	1	250.00	250.00
82	21	29	1	490.00	490.00
83	22	6	1	390.00	390.00
84	22	16	1	790.00	790.00
85	22	25	1	520.00	520.00
86	22	38	1	180.00	180.00
87	23	8	1	410.00	410.00
88	23	17	1	610.00	610.00
89	23	28	1	720.00	720.00
90	23	39	1	320.00	320.00
91	24	9	1	520.00	520.00
92	24	18	1	1650.00	1650.00
93	24	30	1	460.00	460.00
94	24	36	1	220.00	220.00
95	25	3	2	280.00	560.00
96	25	12	1	920.00	920.00
97	25	22	1	330.00	330.00
98	25	31	1	520.00	520.00
99	25	40	1	250.00	250.00
100	26	4	1	680.00	680.00
101	26	13	1	850.00	850.00
102	26	23	1	480.00	480.00
103	26	33	1	430.00	430.00
104	27	5	1	620.00	620.00
105	27	26	1	670.00	670.00
106	27	27	1	530.00	530.00
107	27	32	1	450.00	450.00
108	28	7	1	370.00	370.00
109	28	10	1	390.00	390.00
110	28	21	1	240.00	240.00
111	28	37	1	200.00	200.00
112	29	41	1	620.00	620.00
113	29	46	1	450.00	450.00
114	29	51	1	790.00	790.00
115	29	60	1	240.00	240.00
116	29	66	1	350.00	350.00
117	30	42	1	380.00	380.00
118	30	47	1	390.00	390.00
119	30	52	1	890.00	890.00
120	30	64	1	550.00	550.00
121	30	69	1	420.00	420.00
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orders (id, order_number, order_date, total_amount, payment_method, notes) FROM stdin;
1	ORD-20260401-0001	2026-04-01 10:15:00+03	1800.00	Наличные	Обед, столик у окна
2	ORD-20260401-0002	2026-04-01 12:30:00+03	2070.00	Карта	
3	ORD-20260403-0003	2026-04-03 18:45:00+03	2990.00	Наличные	Заказ с доставкой
4	ORD-20260405-0004	2026-04-05 14:00:00+03	2290.00	Карта	
5	ORD-20260407-0005	2026-04-07 20:10:00+03	2720.00	Наличные	Юбилей, просили свечи
6	ORD-20260410-0006	2026-04-10 09:50:00+03	1640.00	Карта	
7	ORD-20260412-0007	2026-04-12 13:20:00+03	2700.00	Наличные	
8	ORD-20260415-0008	2026-04-15 19:00:00+03	1720.00	Карта	Без глютена
9	ORD-20260418-0009	2026-04-18 11:45:00+03	1810.00	Наличные	
10	ORD-20260420-0010	2026-04-20 21:30:00+03	1690.00	Карта	
11	ORD-20260423-0011	2026-04-23 17:15:00+03	2030.00	Наличные	
12	ORD-20260426-0012	2026-04-26 08:30:00+03	1800.00	Карта	Завтрак
13	ORD-20260428-0013	2026-04-28 12:00:00+03	2620.00	Наличные	
14	ORD-20260430-0014	2026-04-30 16:40:00+03	2870.00	Карта	
15	ORD-20260502-0015	2026-05-02 13:00:00+03	3040.00	Наличные	
16	ORD-20260505-0016	2026-05-05 19:30:00+03	2340.00	Карта	
17	ORD-20260507-0017	2026-05-07 11:10:00+03	2030.00	Наличные	
18	ORD-20260510-0018	2026-05-10 15:25:00+03	2400.00	Карта	
19	ORD-20260513-0019	2026-05-13 20:00:00+03	2000.00	Наличные	
20	ORD-20260516-0020	2026-05-16 10:20:00+03	4990.00	Карта	
21	ORD-20260519-0021	2026-05-19 14:10:00+03	2110.00	Наличные	
22	ORD-20260522-0022	2026-05-22 18:50:00+03	1880.00	Карта	
23	ORD-20260525-0023	2026-05-25 12:30:00+03	2060.00	Наличные	
24	ORD-20260528-0024	2026-05-28 17:20:00+03	2850.00	Карта	
25	ORD-20260530-0025	2026-05-30 21:00:00+03	2580.00	Наличные	
26	ORD-20260602-0026	2026-06-02 09:00:00+03	2440.00	Карта	
27	ORD-20260604-0027	2026-06-04 13:40:00+03	2270.00	Наличные	
28	ORD-20260607-0028	2026-06-07 20:10:00+03	1200.00	Карта	
29	ORD-20260610-0029	2026-06-10 12:00:00+03	2450.00	Наличные	
30	ORD-20260612-0030	2026-06-12 18:00:00+03	2630.00	Карта	
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 8, true);


--
-- Name: dishes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dishes_id_seq', 40, true);


--
-- Name: order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_items_id_seq', 121, true);


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orders_id_seq', 30, true);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: dishes dishes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dishes
    ADD CONSTRAINT dishes_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_order_number_key UNIQUE (order_number);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: idx_dishes_category_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dishes_category_id ON public.dishes USING btree (category_id);


--
-- Name: idx_order_items_dish_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_dish_id ON public.order_items USING btree (dish_id);


--
-- Name: idx_order_items_order_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_order_items_order_id ON public.order_items USING btree (order_id);


--
-- Name: idx_orders_order_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_orders_order_date ON public.orders USING btree (order_date);


--
-- Name: order_items trg_order_items_recalculate_total; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_order_items_recalculate_total AFTER INSERT OR DELETE OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.sync_order_total();


--
-- Name: order_items trg_order_items_set_total; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_order_items_set_total BEFORE INSERT OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION public.set_order_item_line_total();


--
-- Name: dishes dishes_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dishes
    ADD CONSTRAINT dishes_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: order_items order_items_dish_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_dish_id_fkey FOREIGN KEY (dish_id) REFERENCES public.dishes(id);


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict p5IJyfvQv8vAqLLkBtm43FC1hA3jdxmEdZPs0mT01stIGbzLbeuhY5bZPMoPGKq

