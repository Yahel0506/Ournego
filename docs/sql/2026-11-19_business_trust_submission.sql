-- OUR-164 / OUR-170 server trust controls.
-- Apply after 2026-11-19_business_under_review_status.sql and the existing
-- business review migrations. The polygon is INEGI locality 140230001 (2015).
-- Source: https://gaia.inegi.org.mx/wscatgeo/v2/geo/localidades/pol/14/023/U
-- INEGI returns EPSG:6365 metadata with longitude/latitude coordinates; values
-- are explicitly stored as WGS84 geography for PostGIS distance/containment.
begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

do $$ begin create role ournego_listing_submitter nologin noinherit; exception when duplicate_object then null; end $$;
grant usage on schema private to ournego_listing_submitter;
alter role ournego_listing_submitter nologin noinherit nobypassrls;
revoke ournego_listing_submitter from anon, authenticated, service_role;
grant ournego_listing_submitter to postgres;
grant create on schema public to ournego_listing_submitter;

create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
create extension if not exists unaccent with schema extensions;

alter table public.businesses
  add column if not exists published_at timestamptz,
  add column if not exists verified_at timestamptz,
  add column if not exists verification_paused boolean not null default false,
  add column if not exists pending_issue_code text;
update public.businesses set published_at = reviewed_at
 where status = 'approved' and published_at is null and reviewed_at is not null;

create table if not exists private.trust_settings (
  singleton boolean primary key default true check (singleton),
  prohibited_terms text[] not null default '{}',
  shortener_hosts text[] not null default array['bit.ly','tinyurl.com','t.co','goo.gl','is.gd','cutt.ly'],
  pilot_boundary extensions.geometry(MultiPolygon,4326) not null,
  storage_public_origin text,
  business_daily_creation_limit integer not null default 3 check (business_daily_creation_limit > 0),
  business_active_listing_limit integer not null default 10 check (business_active_listing_limit > 0),
  duplicate_radius_m integer not null default 100 check (duplicate_radius_m > 0),
  voter_min_age interval not null default interval '3 days',
  voter_daily_limit integer not null default 15,
  confirmation_window interval not null default interval '7 days',
  confirmation_days smallint not null default 5,
  confirmation_ratio numeric not null default .20,
  velocity_limit integer not null default 60,
  velocity_window interval not null default interval '10 minutes',
  velocity_cooldown interval not null default interval '24 hours',
  report_daily_limit integer not null default 10,
  report_window interval not null default interval '7 days',
  report_threshold integer not null default 3,
  updated_at timestamptz not null default now()
);
alter table private.trust_settings add column if not exists business_daily_creation_limit integer not null default 3 check (business_daily_creation_limit > 0);
alter table private.trust_settings add column if not exists business_active_listing_limit integer not null default 10 check (business_active_listing_limit > 0);
insert into private.trust_settings(singleton,pilot_boundary,storage_public_origin)
values (true, extensions.ST_SetSRID(extensions.ST_GeomFromGeoJSON(
  '{"type":"MultiPolygon","crs":{"type":"name","properties":{"name":"EPSG:6365"}},"coordinates":[[[[-103.456977809,19.731247814],[-103.456433133,19.731185238],[-103.45637178,19.731214831],[-103.45620906,19.731573214],[-103.456079299,19.731859006],[-103.455894107,19.732240608],[-103.45586155,19.732306436],[-103.455826324,19.732377663],[-103.455821686,19.732387041],[-103.454876209,19.732294889],[-103.45429618,19.732238716],[-103.453689666,19.732194216],[-103.452685012,19.732103169],[-103.452272537,19.7320709],[-103.451887935,19.732014369],[-103.45188944,19.732003814],[-103.4519039,19.73190238],[-103.451653239,19.731878856],[-103.451747758,19.731142523],[-103.451750149,19.731124783],[-103.451795799,19.730786068],[-103.451880395,19.730775339],[-103.451882623,19.730775056],[-103.452190896,19.730735956],[-103.452250629,19.730774781],[-103.45226983,19.73066828],[-103.452324719,19.73036397],[-103.45241289,19.72992715],[-103.4524522,19.72949878],[-103.45264717,19.72842369],[-103.45266246,19.72839928],[-103.45344928,19.72714335],[-103.45357235,19.72696775],[-103.45364975,19.72683158],[-103.45371138,19.72673666],[-103.45375354,19.72664434],[-103.45378403,19.7265214],[-103.45384435,19.72645803],[-103.45390922,19.72641714],[-103.45396786,19.72635871],[-103.45408394,19.72622192],[-103.4541182,19.72614877],[-103.45418212,19.7260906],[-103.45432145,19.72596098],[-103.4543756,19.72582609],[-103.45438958,19.725716],[-103.45438132,19.72562914],[-103.45436392,19.72557229],[-103.45432997,19.72550371],[-103.45431618,19.72539623],[-103.45428028,19.72519766],[-103.45434391,19.72498706],[-103.45437855,19.72470637],[-103.45434075,19.7245314],[-103.45436283,19.72425414],[-103.45437757,19.72423272],[-103.4544466,19.72418295],[-103.45459675,19.72408822],[-103.45471134,19.72401055],[-103.45480277,19.72390937],[-103.45482855,19.72385932],[-103.45485938,19.7237676],[-103.45491171,19.72359178],[-103.45497726,19.72347158],[-103.45504277,19.72327458],[-103.453445038,19.723383511],[-103.452977698,19.72341537],[-103.4528258,19.723320601],[-103.452807719,19.723287061],[-103.452789889,19.72322417],[-103.45276297,19.723152511],[-103.452714059,19.723066691],[-103.452675659,19.72303674],[-103.45263169,19.72301369],[-103.45254548,19.72297637],[-103.452416889,19.72294042],[-103.45237455,19.72293655],[-103.452302889,19.722920251],[-103.452214599,19.72290729],[-103.452071229,19.72287645],[-103.45197386,19.72284945],[-103.451883879,19.722822541],[-103.451845349,19.72280652],[-103.45177362,19.72279545],[-103.451746019,19.72279346],[-103.45165229,19.722770021],[-103.45157709,19.72273974],[-103.45153494,19.722716711],[-103.45143563,19.722700171],[-103.451327319,19.722662651],[-103.45123362,19.722639181],[-103.451106739,19.72261718],[-103.45097068,19.72257842],[-103.451025549,19.72254192],[-103.451066049,19.722486421],[-103.45106195,19.722446261],[-103.451060111,19.722430133],[-103.4510544,19.72238003],[-103.45103302,19.72233945],[-103.45099178,19.72228066],[-103.4509532,19.72223132],[-103.45091,19.72217809],[-103.4508598,19.72210648],[-103.45091354,19.72212037],[-103.45094268,19.72212346],[-103.45101885,19.72213757],[-103.45106863,19.72215286],[-103.4511166,19.72216814],[-103.45114637,19.72217051],[-103.45121969,19.72218035],[-103.45130649,19.72217826],[-103.45136469,19.72219365],[-103.45145517,19.72221249],[-103.45144994,19.72205449],[-103.45133038,19.722045],[-103.45118065,19.72180437],[-103.45172598,19.72149237],[-103.45183935,19.72143302],[-103.451926,19.72131375],[-103.452036,19.72112791],[-103.45224071,19.72072443],[-103.45244754,19.72027578],[-103.45262803,19.71980111],[-103.452647082,19.719739241],[-103.45275022,19.719404321],[-103.452840139,19.71893189],[-103.45287611,19.718630511],[-103.452994549,19.71836908],[-103.45315792,19.718064751],[-103.45329971,19.71788926],[-103.453446717,19.717617461],[-103.45346223,19.71758878],[-103.45356322,19.71729174],[-103.45368906,19.71712228],[-103.45373109,19.7170506],[-103.45389314,19.7169742],[-103.45405706,19.71689663],[-103.45424358,19.71684651],[-103.45418554,19.71680722],[-103.45402235,19.71672225],[-103.45395354,19.71666198],[-103.45390395,19.71657205],[-103.45387372,19.71643452],[-103.45386232,19.71630911],[-103.45388245,19.71618397],[-103.45388966,19.71608854],[-103.45388388,19.71603477],[-103.45386554,19.71597494],[-103.45382214,19.715897],[-103.45370383,19.71573483],[-103.4536164,19.71564457],[-103.45355345,19.71563211],[-103.4534714,19.71563735],[-103.45337615,19.71570217],[-103.45291802,19.71611595],[-103.45280942,19.71625825],[-103.45273918,19.71634715],[-103.45268746,19.716478],[-103.45258383,19.71675758],[-103.45247483,19.71694165],[-103.45235323,19.7171256],[-103.45217438,19.71735678],[-103.45211598,19.71735512],[-103.45188066,19.717244],[-103.45198002,19.71703102],[-103.45219783,19.71672035],[-103.45246425,19.71635223],[-103.45253206,19.71624746],[-103.4525662,19.71618237],[-103.45259289,19.71608708],[-103.45264062,19.71584525],[-103.45266286,19.71561522],[-103.45265937,19.7153632],[-103.452637488,19.71516614],[-103.45262177,19.71504915],[-103.45258006,19.71497354],[-103.45245782,19.71481637],[-103.45233425,19.71466889],[-103.45226674,19.71459791],[-103.45223834,19.71455408],[-103.45219635,19.71451809],[-103.45209268,19.71448095],[-103.45165974,19.71434335],[-103.45146778,19.71432135],[-103.45139175,19.71432205],[-103.45130503,19.71432034],[-103.45150391,19.71422849],[-103.45160174,19.71420542],[-103.45166291,19.71418945],[-103.45177552,19.71415258],[-103.451898578,19.71410205],[-103.45196371,19.71406551],[-103.45213782,19.71392697],[-103.45222891,19.71386435],[-103.45236089,19.71375815],[-103.45241529,19.71371485],[-103.45264317,19.71360949],[-103.45271409,19.71356545],[-103.45283523,19.71351294],[-103.45308017,19.71344569],[-103.45317529,19.71340515],[-103.45330263,19.71331378],[-103.45339032,19.71322374],[-103.45346777,19.71313489],[-103.45349751,19.71307212],[-103.45350691,19.71300208],[-103.45351209,19.71292985],[-103.4535042,19.71284752],[-103.45347408,19.71277222],[-103.45338191,19.71258474],[-103.45315665,19.71199382],[-103.45321485,19.71205338],[-103.45327551,19.71213106],[-103.4533902,19.71228689],[-103.45348438,19.71237762],[-103.45361032,19.71246362],[-103.45373632,19.71253963],[-103.45385198,19.71259557],[-103.45393043,19.71267615],[-103.45401415,19.71275682],[-103.45409203,19.71289734],[-103.45412255,19.71301748],[-103.45415306,19.71309766],[-103.45420049,19.71310858],[-103.45424826,19.71308402],[-103.454248692,19.713083493],[-103.45441968,19.71287517],[-103.45445675,19.71282109],[-103.45446288,19.71273097],[-103.45445925,19.71256085],[-103.4544496,19.71246638],[-103.45445022,19.71240146],[-103.45446651,19.71235665],[-103.454466772,19.712356542],[-103.45451422,19.71233708],[-103.45457208,19.71236255],[-103.45463995,19.71244305],[-103.45470246,19.71253349],[-103.45475968,19.71262391],[-103.45481762,19.7126838],[-103.45490131,19.71272502],[-103.45517975,19.71287726],[-103.45538457,19.71299891],[-103.45557323,19.71315038],[-103.45573578,19.71327166],[-103.45587198,19.71338772],[-103.45592969,19.71342817],[-103.455993,19.71343371],[-103.45611511,19.71344088],[-103.45615302,19.71337194],[-103.45624978,19.71274663],[-103.45630083,19.71250098],[-103.45632388,19.712346],[-103.456336,19.71219372],[-103.45634598,19.71209998],[-103.45641611,19.71195968],[-103.45647834,19.71186803],[-103.45652311,19.71181428],[-103.45657197,19.71175918],[-103.45656489,19.71166991],[-103.45657425,19.71162362],[-103.45660965,19.71157028],[-103.4566448,19.71154171],[-103.45669085,19.71151735],[-103.45671502,19.71149694],[-103.45674595,19.71145595],[-103.45677034,19.71141491],[-103.45678826,19.71136351],[-103.45679305,19.71132025],[-103.4567892,19.7112908],[-103.45678505,19.71125154],[-103.45676714,19.71123142],[-103.45672175,19.71121192],[-103.45692257,19.71067795],[-103.455975526,19.710282328],[-103.455425969,19.71005275],[-103.454749259,19.70978703],[-103.454456361,19.709701108],[-103.45337829,19.70938485],[-103.45272634,19.70916695],[-103.45268648,19.70899438],[-103.45267703,19.70893458],[-103.45322712,19.7090094],[-103.4532164,19.70881443],[-103.45306568,19.7082162],[-103.453056787,19.708208719],[-103.452655966,19.707871445],[-103.45221012,19.70749628],[-103.45213114,19.70747334],[-103.451983579,19.707327031],[-103.451881109,19.707218781],[-103.451783939,19.70712891],[-103.45170375,19.707051321],[-103.45159109,19.706956461],[-103.45158365,19.706885941],[-103.45161412,19.706845941],[-103.45173317,19.706773771],[-103.45193462,19.70671674],[-103.45207366,19.70669543],[-103.452098249,19.70658714],[-103.45209932,19.706474621],[-103.452118449,19.70638823],[-103.452130619,19.7063126],[-103.452144919,19.70625212],[-103.452184109,19.706220001],[-103.452232349,19.706196621],[-103.452280539,19.706181891],[-103.452328749,19.706162831],[-103.452395479,19.70612228],[-103.452462429,19.70605577],[-103.45249282,19.705988951],[-103.45251835,19.705948061],[-103.452553229,19.705889941],[-103.452574449,19.7058252],[-103.45260492,19.705747551],[-103.452658079,19.70568958],[-103.45271623,19.705588381],[-103.452772709,19.7054244],[-103.452800689,19.70536842],[-103.452824119,19.70531015],[-103.452848449,19.70516614],[-103.45285792,19.705084001],[-103.452857319,19.705017111],[-103.452860519,19.704943201],[-103.45286729,19.70475315],[-103.452886139,19.70459962],[-103.452908349,19.704482631],[-103.452927119,19.70433609],[-103.45293914,19.70411757],[-103.452945629,19.704088491],[-103.452984709,19.70402311],[-103.45300809,19.703911831],[-103.45302715,19.703865081],[-103.453055049,19.703800751],[-103.453083479,19.70368132],[-103.45310525,19.70360992],[-103.453116919,19.7035584],[-103.452421273,19.70316991],[-103.452306215,19.703157564],[-103.450790231,19.702166931],[-103.449201871,19.701128972],[-103.449230176,19.701121373],[-103.449308699,19.70110029],[-103.449651851,19.701008155],[-103.450028503,19.700907024],[-103.449996049,19.700852001],[-103.449915419,19.70073949],[-103.44983331,19.70065603],[-103.44975657,19.700590401],[-103.4497254,19.700575341],[-103.449712149,19.70056643],[-103.449675489,19.700525491],[-103.449658349,19.70050382],[-103.449639479,19.700488381],[-103.44960785,19.70046591],[-103.44956868,19.700450631],[-103.44951125,19.70045482],[-103.44940171,19.70047902],[-103.449295719,19.700504581],[-103.449243429,19.700539181],[-103.449203629,19.70055668],[-103.44915371,19.70057763],[-103.44911929,19.700633751],[-103.449113509,19.70067003],[-103.44908571,19.70077625],[-103.44904731,19.70082208],[-103.449014219,19.70083291],[-103.44894951,19.700860831],[-103.448905139,19.700877151],[-103.448813969,19.700922251],[-103.44875738,19.700968981],[-103.448719769,19.701007451],[-103.44867794,19.701031631],[-103.44859408,19.701056551],[-103.44851103,19.701105971],[-103.448473599,19.701146251],[-103.448430779,19.70121968],[-103.448404119,19.70126817],[-103.448327539,19.70135969],[-103.44824986,19.701478581],[-103.448137889,19.70148688],[-103.44802097,19.701507281],[-103.447878503,19.70152069],[-103.447654769,19.701458421],[-103.44756578,19.70130991],[-103.447511889,19.701039911],[-103.447510479,19.700714021],[-103.44750348,19.700360771],[-103.44742208,19.70009677],[-103.44745775,19.69969992],[-103.44740386,19.69941411],[-103.447421579,19.699181311],[-103.44723818,19.698764831],[-103.4471292,19.698613251],[-103.44700289,19.698107421],[-103.44696825,19.69784989],[-103.446799749,19.697492291],[-103.446718179,19.697158651],[-103.447039459,19.697115151],[-103.447306089,19.697093051],[-103.44754095,19.69702545],[-103.44787075,19.69689889],[-103.448090289,19.696827],[-103.44858134,19.69702855],[-103.44885966,19.69714398],[-103.449450859,19.69726852],[-103.449992636,19.696413804],[-103.448624921,19.695935587],[-103.446603157,19.695228655],[-103.446518543,19.694926182],[-103.447284661,19.695175078],[-103.447324398,19.694880326],[-103.447373886,19.69488288],[-103.447502517,19.694889519],[-103.447599622,19.694863812],[-103.447827884,19.694957021],[-103.448030527,19.694953119],[-103.448147942,19.694983998],[-103.448321985,19.694923676],[-103.448513611,19.694997055],[-103.448657935,19.694953482],[-103.448676481,19.694947883],[-103.448667689,19.69489366],[-103.448726054,19.694535846],[-103.44872766,19.694526001],[-103.44971362,19.69460971],[-103.449720649,19.69447212],[-103.450212429,19.69423266],[-103.449274219,19.69386037],[-103.448762229,19.692858121],[-103.44870377,19.69236231],[-103.448753249,19.69201652],[-103.44955037,19.691980121],[-103.45080915,19.69250042],[-103.45085357,19.69239208],[-103.451049719,19.69226791],[-103.451451479,19.692192111],[-103.452111649,19.69142323],[-103.45235797,19.691054111],[-103.452276199,19.690844241],[-103.45213331,19.690477507],[-103.452033526,19.690345211],[-103.451985895,19.690348245],[-103.451585328,19.690373763],[-103.451385478,19.690001392],[-103.451098189,19.690142161],[-103.451062027,19.69015988],[-103.450971064,19.689915157],[-103.450953039,19.689866664],[-103.45092805,19.689661973],[-103.450922651,19.68946878],[-103.450922261,19.689454823],[-103.45143414,19.68951789],[-103.452489096,19.689130012],[-103.452998096,19.689222208],[-103.454038172,19.6892841],[-103.454310383,19.688981105],[-103.454374153,19.688910122],[-103.452220519,19.68696698],[-103.45259063,19.686305911],[-103.452651879,19.68623014],[-103.452762799,19.68613528],[-103.4529342,19.685984021],[-103.453092,19.68601683],[-103.453092352,19.686016573],[-103.45339265,19.68579717],[-103.45350005,19.68571831],[-103.45368569,19.68545052],[-103.45402734,19.6848144],[-103.45413422,19.68459655],[-103.4543754,19.68439908],[-103.45440637,19.68422978],[-103.45454162,19.68423765],[-103.45464922,19.6845402],[-103.4548368,19.68459582],[-103.45527103,19.68470814],[-103.45570842,19.684803261],[-103.45645271,19.68490189],[-103.456561474,19.684913505],[-103.456561562,19.684912533],[-103.456576963,19.684742531],[-103.456422749,19.684548147],[-103.456260661,19.684419429],[-103.456222532,19.684077269],[-103.45660848,19.684186516],[-103.456564081,19.683818123],[-103.456391676,19.683604883],[-103.456631686,19.683363],[-103.456710767,19.683414071],[-103.456834055,19.683435401],[-103.457021623,19.683548772],[-103.457203642,19.683735108],[-103.457362909,19.68411794],[-103.45780058,19.68416697],[-103.457897259,19.684138296],[-103.458077583,19.684084814],[-103.4580778,19.684084754],[-103.45819069,19.68405365],[-103.458395261,19.684003135],[-103.458395478,19.684003077],[-103.458757889,19.68390798],[-103.459162114,19.683774471],[-103.459532569,19.68358],[-103.459702247,19.68344798],[-103.45977508,19.68339131],[-103.46000005,19.68316234],[-103.46034532,19.68253923],[-103.46066489,19.68161046],[-103.460587492,19.681484689],[-103.460707981,19.681139728],[-103.460693125,19.680633878],[-103.460701791,19.680242048],[-103.460780193,19.679857795],[-103.460788049,19.679263899],[-103.460900756,19.67900249],[-103.461033488,19.67891252],[-103.461156714,19.678919106],[-103.46152091,19.67797532],[-103.461524366,19.677950851],[-103.461588207,19.67749896],[-103.46159492,19.67745145],[-103.461604138,19.677396565],[-103.46167514,19.676973821],[-103.461718111,19.67678714],[-103.46176946,19.67656408],[-103.46170665,19.67622655],[-103.4617596,19.67608738],[-103.46167518,19.67604463],[-103.461686059,19.676026634],[-103.46180203,19.67583478],[-103.461893247,19.675683668],[-103.46207065,19.67538978],[-103.46214794,19.67516243],[-103.46221632,19.67481288],[-103.46218437,19.67466571],[-103.46276102,19.67461698],[-103.46287217,19.67464302],[-103.46291791,19.67472937],[-103.46293503,19.67482425],[-103.46302938,19.67509302],[-103.46319017,19.67493025],[-103.463349576,19.674926238],[-103.46357002,19.67492069],[-103.463981459,19.67491037],[-103.463982012,19.674912537],[-103.46407205,19.67526608],[-103.46418597,19.67596425],[-103.46377657,19.67596002],[-103.46355168,19.67589672],[-103.46343123,19.67619877],[-103.46329237,19.67658622],[-103.46314495,19.67697637],[-103.46297671,19.67740658],[-103.46285023,19.67773271],[-103.464088849,19.677911911],[-103.46455275,19.677979031],[-103.46503134,19.67805089],[-103.46560557,19.67813711],[-103.465625509,19.67801103],[-103.465684739,19.67779652],[-103.46572929,19.67754814],[-103.465809997,19.677210073],[-103.46582903,19.67713035],[-103.46588211,19.676820341],[-103.46582525,19.676742821],[-103.46573132,19.67665974],[-103.465719457,19.676643023],[-103.46568172,19.67658983],[-103.465611569,19.676448451],[-103.465535979,19.676063851],[-103.46543968,19.675825321],[-103.46541075,19.675616631],[-103.465363259,19.67552846],[-103.465319472,19.675373985],[-103.465237442,19.675250825],[-103.465123769,19.67502496],[-103.465076481,19.674952994],[-103.465098448,19.674856837],[-103.465122371,19.674826188],[-103.465196677,19.67473099],[-103.465663731,19.674745434],[-103.466295804,19.674891691],[-103.466490199,19.674936671],[-103.466855674,19.675096893],[-103.467017997,19.675023339],[-103.468237261,19.675000045],[-103.468320762,19.67499845],[-103.468372614,19.674997459],[-103.468337577,19.675246905],[-103.469016007,19.67499628],[-103.469148889,19.674912988],[-103.469188606,19.674888092],[-103.469332172,19.674798101],[-103.46959972,19.67486646],[-103.46959822,19.6743012],[-103.47057618,19.67440392],[-103.47023731,19.67462806],[-103.47022845,19.67489408],[-103.470702999,19.674920281],[-103.47080298,19.67493465],[-103.470947679,19.67494175],[-103.47123574,19.67532557],[-103.47128266,19.67538674],[-103.47144732,19.675607511],[-103.471637719,19.67585692],[-103.471767079,19.67604808],[-103.47226848,19.67657452],[-103.472105849,19.67745131],[-103.472064538,19.67765592],[-103.47206375,19.677659831],[-103.47162132,19.67781362],[-103.471820676,19.678248902],[-103.47190317,19.678429021],[-103.47207682,19.678687851],[-103.472687709,19.678848511],[-103.473207119,19.678974031],[-103.47365066,19.678172651],[-103.473730479,19.678028431],[-103.47403886,19.677457711],[-103.474090459,19.67736225],[-103.47437898,19.67682829],[-103.474912638,19.677021711],[-103.47530532,19.67716402],[-103.47501128,19.67772322],[-103.47486403,19.67800325],[-103.477116883,19.677973304],[-103.477121677,19.676047091],[-103.477121853,19.675976592],[-103.477851826,19.675934964],[-103.478004478,19.675929497],[-103.479612179,19.67587191],[-103.48206474,19.67580006],[-103.48204252,19.67537125],[-103.482051889,19.675260061],[-103.482078979,19.67493868],[-103.48207714,19.674545431],[-103.482047419,19.67377129],[-103.482033014,19.673489371],[-103.482216645,19.67349919],[-103.48482717,19.67363875],[-103.48574235,19.67594634],[-103.48621977,19.67703155],[-103.486382716,19.677394437],[-103.48665797,19.678007431],[-103.486779284,19.678069795],[-103.486786207,19.678083735],[-103.488394095,19.681321102],[-103.486897542,19.681385174],[-103.48677838,19.6813168],[-103.48680118,19.681622111],[-103.48678522,19.681820911],[-103.48678805,19.682031231],[-103.48679328,19.68242151],[-103.48824006,19.68238335],[-103.48881051,19.68239188],[-103.48932275,19.68365677],[-103.48839338,19.68427929],[-103.486823579,19.685127111],[-103.48688031,19.68694223],[-103.48691586,19.68901192],[-103.48694234,19.69033162],[-103.486822982,19.693578376],[-103.488887614,19.69364614],[-103.48899725,19.69539723],[-103.48939539,19.695404069],[-103.489615919,19.697932762],[-103.488975164,19.698065786],[-103.489019567,19.69877876],[-103.487819424,19.699006886],[-103.487707409,19.699880292],[-103.487746827,19.70196946],[-103.487017985,19.702066102],[-103.486275716,19.70216452],[-103.48627598,19.70217769],[-103.48633355,19.70255545],[-103.486370099,19.7026678],[-103.48777566,19.70698823],[-103.48769882,19.70701646],[-103.48666018,19.70714495],[-103.48638148,19.70578485],[-103.48619348,19.7057998],[-103.48535237,19.70586622],[-103.4845432,19.70593034],[-103.48383366,19.70599845],[-103.48346614,19.70602017],[-103.48346208,19.70796558],[-103.48259886,19.70799649],[-103.48262851,19.70845702],[-103.48273029,19.70894815],[-103.48280415,19.70934605],[-103.48289275,19.70976025],[-103.48229829,19.70974906],[-103.48234386,19.7099302],[-103.48257748,19.71067231],[-103.48278515,19.71123848],[-103.48287329,19.7114406],[-103.48302925,19.71174691],[-103.48327909,19.71225823],[-103.48353477,19.71270791],[-103.48391069,19.71325178],[-103.48426952,19.71368397],[-103.48469895,19.71433178],[-103.48240232,19.71367803],[-103.481904,19.71342057],[-103.481284215,19.713357015],[-103.481247356,19.714158383],[-103.480257766,19.714100599],[-103.480242929,19.714099733],[-103.48023092,19.71455618],[-103.480129619,19.715653831],[-103.4800922,19.71602057],[-103.480021773,19.717077404],[-103.478490602,19.717049582],[-103.47766906,19.71680703],[-103.477679319,19.71682845],[-103.477736349,19.71763511],[-103.47776845,19.71806015],[-103.477768844,19.71809472],[-103.477774183,19.718563089],[-103.477774185,19.718563354],[-103.47783628,19.71961762],[-103.47666302,19.71979223],[-103.476636984,19.719795443],[-103.47571248,19.71999957],[-103.47605526,19.72088331],[-103.47316718,19.72402189],[-103.47030918,19.72449982],[-103.46972972,19.72371114],[-103.46926291,19.72306594],[-103.46869974,19.72233015],[-103.46821148,19.724935646],[-103.46812589,19.72542435],[-103.4680976,19.72566905],[-103.46782955,19.72560517],[-103.46688665,19.72528506],[-103.46515897,19.724739551],[-103.464792519,19.72462383],[-103.464469769,19.72749143],[-103.463108198,19.727268631],[-103.462721909,19.730089711],[-103.461914479,19.72999031],[-103.461915519,19.731112311],[-103.4619072,19.731711832],[-103.461907192,19.731719287],[-103.461907146,19.731761031],[-103.461888197,19.731762051],[-103.461884294,19.731762261],[-103.461836659,19.732859778],[-103.461812348,19.733419898],[-103.460809068,19.733427381],[-103.459620782,19.733431122],[-103.459620748,19.732077227],[-103.459612947,19.731745066],[-103.459582829,19.731744332],[-103.459538619,19.731741511],[-103.45881808,19.731725691],[-103.458742752,19.731650499],[-103.458158918,19.731593717],[-103.457569719,19.731425848],[-103.456977809,19.731247814]]]]}'),4326),null)
on conflict (singleton) do nothing;
revoke all on private.trust_settings from public, anon, authenticated;

create table if not exists private.business_creation_daily_usage (
  owner_id uuid not null references auth.users(id) on delete cascade,
  local_date date not null,
  created_count integer not null check (created_count >= 1),
  primary key(owner_id,local_date)
);
revoke all on private.business_creation_daily_usage from public, anon, authenticated;

create or replace function private.record_listing_creation()
returns trigger language plpgsql volatile security definer
set search_path = pg_catalog, public, private, auth
as $$
declare actor uuid := auth.uid(); today date := (now() at time zone 'America/Mexico_City')::date; used integer; active_count integer; active_limit integer; daily_limit integer;
begin
  if actor is null or new.owner_id is distinct from actor then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended('listing-owner:'||actor::text,164));
  select business_active_listing_limit,business_daily_creation_limit into active_limit,daily_limit from private.trust_settings where singleton;
  select count(*) into active_count from public.businesses b where b.owner_id=actor and b.is_active is not false and b.status in ('pending','approved','under_review');
  if active_count > active_limit then raise exception 'business_active_limit' using errcode='P0001'; end if;
  insert into private.business_creation_daily_usage(owner_id,local_date,created_count)
    values(actor,today,1)
    on conflict(owner_id,local_date) do update
      set created_count=private.business_creation_daily_usage.created_count+1
    returning created_count into used;
  if used > daily_limit then raise exception 'business_daily_limit' using errcode='P0001'; end if;
  return new;
end $$;

create or replace function private.normalized_listing_name(value text)
returns text language sql immutable strict set search_path = pg_catalog
as $$ select regexp_replace(lower(extensions.unaccent(btrim(value))), '[^[:alnum:]]+', '', 'g') $$;

create or replace function private.listing_review_reason(
  p_name text, p_description text, p_phone text, p_lat double precision,
  p_lon double precision, p_business_id uuid, p_owner uuid
) returns text language plpgsql volatile security definer
set search_path = pg_catalog, public, private, extensions
as $$
declare cfg private.trust_settings%rowtype; candidate text; body text;
begin
  select * into strict cfg from private.trust_settings where singleton;
  if not extensions.ST_Covers(cfg.pilot_boundary,
       extensions.ST_SetSRID(extensions.ST_MakePoint(p_lon,p_lat),4326)) then
    return 'outside_pilot';
  end if;
  body := lower(coalesce(p_name,'') || ' ' || coalesce(p_description,''));
  foreach candidate in array cfg.prohibited_terms loop
    if length(btrim(candidate)) > 0 and position(lower(btrim(candidate)) in body) > 0 then
      return 'prohibited_language';
    end if;
  end loop;
  if coalesce(p_phone,'') ~ '(.)\1{6,}' then return 'suspicious_contact'; end if;
  foreach candidate in array cfg.shortener_hosts loop
    if length(btrim(candidate))>0 and position(lower(btrim(candidate)) in lower(coalesce(p_description,'')))>0 then return 'suspicious_contact'; end if;
  end loop;
  perform pg_advisory_xact_lock(hashtextextended('listing-name:'||private.normalized_listing_name(p_name),165));
  if exists (
    select 1 from public.businesses b
    where b.business_id <> coalesce(p_business_id,'00000000-0000-0000-0000-000000000000'::uuid)
      and b.is_active is not false
      and b.status not in ('withdrawn','rejected')
      and private.normalized_listing_name(b.name) = private.normalized_listing_name(p_name)
      and extensions.ST_DWithin(
        extensions.ST_SetSRID(extensions.ST_MakePoint(b.longitude,b.latitude),4326)::extensions.geography,
        extensions.ST_SetSRID(extensions.ST_MakePoint(p_lon,p_lat),4326)::extensions.geography,
        cfg.duplicate_radius_m)
  ) then return 'possible_duplicate'; end if;
  return null;
end $$;
revoke all on function private.listing_review_reason(text,text,text,double precision,double precision,uuid,uuid) from public, anon, authenticated;
grant execute on function private.listing_review_reason(text,text,text,double precision,double precision,uuid,uuid) to ournego_listing_submitter, authenticated;

create or replace function private.validate_listing_payload(p jsonb, h jsonb, actor uuid)
returns text language plpgsql volatile security definer
set search_path = pg_catalog, public, private, extensions, auth
as $$
declare name text := p->>'name'; lat double precision; lon double precision; typ integer; image_obj text; image_url text; phone text; hour jsonb;
begin
  if actor is null or not exists (select 1 from public.users u where u.id=actor and u.has_profile and nullif(btrim(u.name),'') is not null) then
    raise exception 'profile_required' using errcode='42501';
  end if;
  phone:=private.validate_listing_basics(p);
  begin lat := (p->>'latitude')::double precision; lon := (p->>'longitude')::double precision; typ := (p->>'type')::integer;
  exception when others then raise exception 'invalid_listing' using errcode='23514'; end;
  if p->>'business_id' is null or (p->>'business_id') !~* '^[0-9a-f-]{36}$'
     or length(btrim(name)) < 3 or typ not between 0 and 12
     or nullif(btrim(p->>'address'),'') is null
     or lat is null or lon is null or lat in ('Infinity'::float8,'-Infinity'::float8,'NaN'::float8)
     or lon in ('Infinity'::float8,'-Infinity'::float8,'NaN'::float8)
     or lat not between -90 and 90 or lon not between -180 and 180 or (lat=0 and lon=0)
     or coalesce(jsonb_typeof(h)='array',false)=false then raise exception 'invalid_listing' using errcode='23514'; end if;
  image_obj := p->>'image_object'; image_url := p->>'image_url';
  if jsonb_typeof(p) <> 'object' or jsonb_typeof(h) <> 'array'
     or image_obj is null or image_obj !~ ('^' || (p->>'business_id') || '/[A-Za-z0-9._% -]+$')
     or image_obj ~ '(^|/)\.\.(/|$)'
     or not private.owns_listing_image(image_url,image_obj,actor) then
    raise exception 'invalid_listing' using errcode='23514';
  end if;
  for hour in select value from jsonb_array_elements(h) loop
    if jsonb_typeof(hour)<>'object'
       or coalesce((hour->>'day_of_week') ~ '^[1-7]$',false)=false
       or coalesce((hour->>'opening_time') ~ '^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$',false)=false
       or coalesce((hour->>'closing_time') ~ '^(([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?|24:00(:00)?)$',false)=false then
      raise exception 'invalid_listing' using errcode='23514';
    end if;
    if (hour->>'opening_time')::time = (hour->>'closing_time')::time then raise exception 'invalid_listing' using errcode='23514'; end if;
  end loop;
  return phone;
end $$;
revoke all on function private.validate_listing_payload(jsonb,jsonb,uuid) from public, anon, authenticated;
grant execute on function private.validate_listing_payload(jsonb,jsonb,uuid) to ournego_listing_submitter;

create or replace function private.request_actor()
returns uuid language sql stable security definer
set search_path = pg_catalog, auth
as $$ select auth.uid() $$;
revoke all on function private.request_actor() from public,anon;
grant execute on function private.request_actor() to authenticated,ournego_listing_submitter;

create or replace function private.validate_listing_basics(p jsonb)
returns text language plpgsql stable security definer
set search_path = pg_catalog, public
as $$
declare name text:=p->>'name'; lat double precision; lon double precision; typ integer; phone text;
begin
  if jsonb_typeof(p)<>'object' then raise exception 'invalid_listing' using errcode='23514'; end if;
  begin lat:=(p->>'latitude')::double precision; lon:=(p->>'longitude')::double precision; typ:=(p->>'type')::integer;
  exception when others then raise exception 'invalid_listing' using errcode='23514'; end;
  if length(btrim(coalesce(name,'')))<3 or typ is null or typ not between 0 and 12
     or nullif(btrim(p->>'address'),'') is null
     or lat is null or lon is null or lat in ('Infinity'::float8,'-Infinity'::float8,'NaN'::float8)
     or lon in ('Infinity'::float8,'-Infinity'::float8,'NaN'::float8)
     or lat not between -90 and 90 or lon not between -180 and 180 or (lat=0 and lon=0) then
    raise exception 'invalid_listing' using errcode='23514';
  end if;
  phone:=nullif(regexp_replace(coalesce(p->>'phone_number',''),'\D','','g'),'');
  if phone is not null and length(phone) not between 7 and 15 then raise exception 'invalid_listing' using errcode='23514'; end if;
  return phone;
end $$;
revoke all on function private.validate_listing_basics(jsonb) from public,anon;
grant execute on function private.validate_listing_basics(jsonb) to authenticated,ournego_listing_submitter;

create or replace function private.owns_listing_image(p_url text,p_object text,p_owner uuid)
returns boolean language plpgsql stable security definer
set search_path = pg_catalog, public, private
as $$
declare origin text; bucket_prefix text; path text; decoded_path text;
begin
  select storage_public_origin into origin from private.trust_settings where singleton;
  if origin is null or p_url is null or p_object is null or p_owner is null then return false; end if;
  bucket_prefix:=origin||'/storage/v1/object/public/businesses_pictures/';
  if left(p_url,length(bucket_prefix))<>bucket_prefix or p_url ~ '[?#]' then return false; end if;
  path:=substr(p_url,length(bucket_prefix)+1);
  decoded_path:=replace(path,'%20',' ');
  if path<>p_object and decoded_path<>p_object then return false; end if;
  if p_object !~ '^[0-9a-fA-F-]{36}/[^/]+$' or p_object ~ '(^|/)\.\.(/|$)' then return false; end if;
  return exists(select 1 from storage.objects o where o.bucket_id='businesses_pictures' and o.name=p_object and (o.owner=p_owner or o.owner_id=p_owner::text));
end $$;
revoke all on function private.owns_listing_image(text,text,uuid) from public,anon;
grant execute on function private.owns_listing_image(text,text,uuid) to authenticated,ournego_listing_submitter;

create or replace function private.has_valid_listing_image(p_images text[],p_owner uuid,p_required boolean)
returns boolean language plpgsql stable security definer
set search_path = pg_catalog, public, private
as $$
declare image text; object_path text; found_image boolean:=false;
begin
  if p_images is null then return false; end if;
  foreach image in array p_images loop
    if nullif(btrim(image),'') is null then continue; end if;
    object_path:=regexp_replace(image,'^.*/storage/v1/object/public/businesses_pictures/','');
    if not private.owns_listing_image(image,replace(object_path,'%20',' '),p_owner) then return false; end if;
    found_image:=true;
  end loop;
  return found_image or not p_required;
end $$;
revoke all on function private.has_valid_listing_image(text[],uuid,boolean) from public,anon;
grant execute on function private.has_valid_listing_image(text[],uuid,boolean) to authenticated,ournego_listing_submitter;

create or replace function private.ensure_owner_active_capacity(p_owner uuid,p_excluded uuid)
returns void language plpgsql volatile security definer
set search_path = pg_catalog, public, private
as $$
declare limit_count integer; active_count integer;
begin
  perform pg_advisory_xact_lock(hashtextextended('listing-owner:'||p_owner::text,164));
  select business_active_listing_limit into limit_count from private.trust_settings where singleton;
  select count(*) into active_count from public.businesses b where b.owner_id=p_owner and b.business_id<>p_excluded and b.is_active is not false and b.status in ('pending','approved','under_review');
  if active_count>=limit_count then raise exception 'business_active_limit' using errcode='P0001'; end if;
end $$;
revoke all on function private.ensure_owner_active_capacity(uuid,uuid) from public,anon;
grant execute on function private.ensure_owner_active_capacity(uuid,uuid) to authenticated,ournego_listing_submitter;

create or replace function private.has_complete_profile(p_user uuid)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$ select exists(select 1 from public.users u where u.id=p_user and u.has_profile and nullif(btrim(u.name),'') is not null) $$;
revoke all on function private.has_complete_profile(uuid) from public,anon;
grant execute on function private.has_complete_profile(uuid) to authenticated,ournego_listing_submitter;

create or replace function private.enforce_listing_trust()
returns trigger language plpgsql set search_path = pg_catalog, public, private, auth
as $$
declare
  uid uuid := private.request_actor();
  caller text := current_user;
  reason text;
  was_reviewer boolean;
  identity_changed boolean;
  image_changed boolean;
  payload jsonb;
  image_url text;
  origin_prefix text;
begin
  if tg_op='INSERT' then
    if caller='ournego_listing_submitter' then
      if new.owner_id is distinct from uid or new.status not in ('approved','pending') then
        raise exception 'invalid_listing' using errcode='42501';
      end if;
      perform private.validate_listing_basics(jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number));
      if new.status='approved' and not private.has_valid_listing_image(new.images,new.owner_id,true) then
        raise exception 'invalid_listing' using errcode='23514';
      end if;
      new.published_at:=case when new.status='approved' then coalesce(new.published_at,now()) end;
      new.pending_issue_code:=case when new.status='pending' then new.pending_issue_code end;
    elsif uid is not null then
      if not private.has_complete_profile(uid) then raise exception 'profile_required' using errcode='42501'; end if;
      if new.owner_id is distinct from uid or new.status<>'pending'
         or new.published_at is not null or new.verified_at is not null
         or new.verification_paused or new.pending_issue_code is not null then
        raise exception 'invalid_listing' using errcode='42501';
      end if;
      payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
      perform private.validate_listing_basics(payload);
      new.status:='pending';
      new.created_at:=now();
      new.pending_issue_code:='legacy';
    end if;
    return new;
  end if;

  if uid is null then return new; end if;
  was_reviewer:=old.owner_id is distinct from uid and public.is_reviewer();
  if old.owner_id is distinct from uid and not was_reviewer then
    raise exception 'business status change not allowed' using errcode='42501';
  end if;

  if was_reviewer and new.status is distinct from old.status then
    if (old.status,new.status) not in (('pending','approved'),('pending','rejected'),('approved','withdrawn'),('under_review','approved'),('under_review','withdrawn')) then
      raise exception 'invalid_business_transition' using errcode='42501';
    end if;
    if new.status in ('rejected','withdrawn') and nullif(btrim(new.rejection_reason),'') is null then
      raise exception 'invalid_listing' using errcode='23514';
    end if;
    if (to_jsonb(new)-'status'-'rejection_reason') is distinct from (to_jsonb(old)-'status'-'rejection_reason') then
      raise exception 'reviewer_status_only' using errcode='42501';
    end if;
    if new.status='approved' then
      payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
      perform private.validate_listing_basics(payload);
      if old.status='pending' and not private.has_valid_listing_image(new.images,old.owner_id,true) then
        raise exception 'invalid_listing' using errcode='23514';
      end if;
      new.rejection_reason:=null;
      new.pending_issue_code:=null;
      new.published_at:=coalesce(old.published_at,now());
    elsif new.status in ('rejected','withdrawn') then
      new.pending_issue_code:=null;
    end if;
    new.reviewed_at:=now();
    return new;
  end if;

  if old.owner_id is distinct from uid then raise exception 'business status change not allowed' using errcode='42501'; end if;

  -- Owner-controlled writes cannot alter identity, lifecycle, activity, or trust metadata.
  new.business_id:=old.business_id;
  new.owner_id:=old.owner_id;
  new.created_at:=old.created_at;
  new.is_active:=old.is_active;
  new.reviewed_at:=old.reviewed_at;
  new.submitted_at:=old.submitted_at;
  new.published_at:=old.published_at;
  new.verified_at:=old.verified_at;
  new.verification_paused:=old.verification_paused;
  new.pending_issue_code:=old.pending_issue_code;

  identity_changed:=new.name is distinct from old.name or new.type is distinct from old.type or new.address is distinct from old.address or new.latitude is distinct from old.latitude or new.longitude is distinct from old.longitude;
  image_changed:=new.images is distinct from old.images;
  if identity_changed then new.verified_at:=null; end if;

  if new.status is distinct from old.status then
    if new.status='withdrawn' and old.status<>'under_review' then new.rejection_reason:=null; return new; end if;
    if new.status='pending' and old.status in ('rejected','withdrawn') then
      payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
      perform private.validate_listing_basics(payload);
      if not private.has_valid_listing_image(new.images,uid,true) then raise exception 'invalid_listing' using errcode='23514'; end if;
      perform private.ensure_owner_active_capacity(uid,old.business_id);
      new.rejection_reason:=null;
      new.pending_issue_code:='legacy';
      new.submitted_at:=now();
      return new;
    end if;
    raise exception 'business status change not allowed' using errcode='42501';
  end if;

  payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
  if new.name is distinct from old.name or new.description is distinct from old.description or new.type is distinct from old.type or new.address is distinct from old.address or new.latitude is distinct from old.latitude or new.longitude is distinct from old.longitude or new.phone_number is distinct from old.phone_number or image_changed then
    perform private.validate_listing_basics(payload);
  end if;
  if image_changed and not private.has_valid_listing_image(new.images,uid,true) then
    raise exception 'invalid_listing' using errcode='23514';
  end if;

  -- Public edits to an approved listing can send it back to review, never republish a hidden row.
  if old.status='approved' and (new.name is distinct from old.name or new.description is distinct from old.description or new.type is distinct from old.type or new.address is distinct from old.address or new.latitude is distinct from old.latitude or new.longitude is distinct from old.longitude or new.phone_number is distinct from old.phone_number or image_changed) then
    reason:=private.listing_review_reason(new.name,concat_ws(' ',new.description,new.address),new.phone_number,new.latitude,new.longitude,new.business_id,new.owner_id);
    if reason is not null then new.status:='pending'; new.submitted_at:=now(); new.pending_issue_code:=reason; new.rejection_reason:=null; end if;
  end if;
  return new;
end $$;

-- Replace previous guard with an invoker guard so it can distinguish the
-- dedicated RPC owner from the general postgres SECURITY DEFINER functions.
drop trigger if exists businesses_enforce_status_change on public.businesses;
create trigger businesses_enforce_status_change before insert or update on public.businesses
for each row execute function private.enforce_listing_trust();
drop trigger if exists businesses_record_creation_quota on public.businesses;
create trigger businesses_record_creation_quota after insert on public.businesses
for each row execute function private.record_listing_creation();

create or replace function private.log_trust_status_change()
returns trigger language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare actor text;
begin
  if tg_op='UPDATE' and new.status is not distinct from old.status then return new; end if;
  actor:=case when auth.uid() is null then 'system' when tg_op='INSERT' and new.status='approved' and new.published_at is not null then 'system' when tg_op='UPDATE' and old.status='approved' and new.status='pending' and new.pending_issue_code is not null then 'system' when public.is_reviewer() and old.owner_id is distinct from auth.uid() then 'reviewer' else 'owner' end;
  insert into public.business_review_log(business_id,actor_id,actor_role,from_status,to_status,reason)
  values(new.business_id,case when actor='system' then null else auth.uid() end,actor,case when tg_op='UPDATE' then old.status end,new.status,
    case when new.status in ('rejected','withdrawn') then new.rejection_reason when new.status='pending' then new.pending_issue_code end);
  return new;
end $$;
drop trigger if exists businesses_log_status_change on public.businesses;
create trigger businesses_log_status_change after insert or update on public.businesses
for each row execute function private.log_trust_status_change();

-- Least-privilege role is reachable only via the typed RPC; it cannot be SET ROLE'd by app users.
grant usage on schema public, extensions to ournego_listing_submitter;
grant select on public.businesses to ournego_listing_submitter;
grant insert (business_id, owner_id, name, description, type, address, latitude, longitude, phone_number, images, status, submitted_at, published_at, pending_issue_code) on public.businesses to ournego_listing_submitter;
grant insert (business_id, day_of_week, opening_time, closing_time) on public.business_hours to ournego_listing_submitter;
drop policy if exists businesses_select_submitter_owner on public.businesses;
create policy businesses_select_submitter_owner on public.businesses for select to ournego_listing_submitter using (true);
drop policy if exists businesses_insert_submitter_owner on public.businesses;
create policy businesses_insert_submitter_owner on public.businesses for insert to ournego_listing_submitter with check (owner_id=private.request_actor() and status in ('approved','pending'));
drop policy if exists hours_insert_submitter_owner on public.business_hours;
create policy hours_insert_submitter_owner on public.business_hours for insert to ournego_listing_submitter with check (exists(select 1 from public.businesses b where b.business_id=business_hours.business_id and b.owner_id=private.request_actor()));

create or replace function public.submit_business_listing(p_listing jsonb,p_hours jsonb)
returns jsonb language plpgsql volatile security definer
set search_path = pg_catalog, public, private, auth, extensions
as $$
declare actor uuid:=private.request_actor(); bid uuid; phone text; reason text; row_data public.businesses%rowtype; hour jsonb;
begin
  if actor is null then raise exception 'profile_required' using errcode='42501'; end if;
  begin bid:=(p_listing->>'business_id')::uuid; exception when others then raise exception 'invalid_listing' using errcode='23514'; end;
  perform pg_advisory_xact_lock(hashtextextended('listing-owner:'||actor::text,164));
  select * into row_data from public.businesses where business_id=bid;
  if found then
    if row_data.owner_id<>actor then raise exception 'invalid_listing' using errcode='42501'; end if;
    return jsonb_build_object('business_id',bid,'status',row_data.status,'review_pending_reason',case when row_data.status='approved' then null else row_data.pending_issue_code end);
  end if;
  phone:=private.validate_listing_payload(p_listing,p_hours,actor);
  reason:=private.listing_review_reason(p_listing->>'name',concat_ws(' ',p_listing->>'description',p_listing->>'address'),phone,(p_listing->>'latitude')::float8,(p_listing->>'longitude')::float8,bid,actor);
  insert into public.businesses(business_id,owner_id,name,description,type,address,latitude,longitude,phone_number,images,status,submitted_at,published_at,pending_issue_code)
  values(bid,actor,btrim(p_listing->>'name'),nullif(btrim(p_listing->>'description'),''),(p_listing->>'type')::smallint,btrim(p_listing->>'address'),(p_listing->>'latitude')::float8,(p_listing->>'longitude')::float8,phone,array[p_listing->>'image_url'],case when reason is null then 'approved'::public.business_status else 'pending'::public.business_status end,now(),case when reason is null then now() end,reason);
  for hour in select value from jsonb_array_elements(p_hours) loop
    insert into public.business_hours(business_id,day_of_week,opening_time,closing_time)
    values(bid,(hour->>'day_of_week')::integer,(hour->>'opening_time')::time,(hour->>'closing_time')::time);
  end loop;
  return jsonb_build_object('business_id',bid,'status',case when reason is null then 'approved' else 'pending' end,'review_pending_reason',reason);
end $$;
alter function public.submit_business_listing(jsonb,jsonb) owner to ournego_listing_submitter;
revoke create on schema public from ournego_listing_submitter;
revoke all on function public.submit_business_listing(jsonb,jsonb) from public, anon;
grant execute on function public.submit_business_listing(jsonb,jsonb) to authenticated;

-- Before enabling the RPC, configure trust_settings.storage_public_origin to the exact
-- public Supabase origin (https://<project-ref>.supabase.co). Keep schema `private`
-- out of PostgREST's exposed schemas; it contains runtime trust configuration.
-- The API payload is the only auto-publish entry point. Existing direct INSERT
-- grants and RLS remain restricted to authenticated owners creating pending rows.
commit;
