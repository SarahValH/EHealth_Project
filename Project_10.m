%E-health methods and applications
%Project- Part 1
%Laboratory 1
%Authors:CONTRINO Paolo, CRIPPA Dario, DORIZZA Andrea
%GONZ�LEZ Diana,ROZO Andrea, VALDERRAMA Sarah

clc
clear
close all


%_______________URL Variable declaration and reading______________%

app_store = 'https://itunes.apple.com/us/genre/ios/id36?mt=8'; 
root = 'https://itunes.apple.com/us/genre/';
url_beginning = webread(app_store);
categories = ["ios-medical", "ios-health-fitness"];

%___Initialization of vector containing the alphabet characters___%

cont = 1;
ASCII = char(27);
for op = 65 : 90
    ASCII(cont) = char(op);
    cont = cont + 1;
end
ASCII(end+1) = char(42);   % #

app_list_links = {};

% Initializes the result structure to be filled with the APPs information
app.URL = {};
app.name = {};
app.id = {};
app.category = {};

%__In each loop iteration extracts the Apps from each category_____%

for i = 1 : length(categories)       % from category 1 to the last
    for j = 1 : length(ASCII)
        t = extractBetween(url_beginning, categories(i), "?mt=8");  % Extracts the piece of URL of that category
        new_url = strcat(root, categories(i), t{1,1}, "?mt=8"); % Concatenates the root URL with the category URL
        html_data = webread(new_url); % Reads the html code
        new_url_let = strcat(new_url, "&letter=");
        band = 0;
        page = 0;
        bandcontrol_no_next = 0;
        cont_no_next = 1;
        % Control for pages
        while (band == 0)
            page = page + 1;
            strpage = string(page);
            new_url_letp = strcat(new_url_let, ASCII(j), "&page=", strpage, "#page");
            html_data_let = webread(new_url_letp);
            % Extracts from the html, the piece of text containing the applist
            txt_chunk = extractBetween(html_data_let, '<ul>', '</ul>');
            % Check if there's a paginate-more in the html which
            % indicates if there's a NEXT page, as once we are in the
            % last page there's no NEXT option in the pagination
            paginate_more = strfind(html_data_let, 'paginate-more">Next</a>');
            app_list_links = {};
            %Extracts from the piece of text, the app links and put them in an array
            for indxChunk = 1 : size(txt_chunk,1)
                app_list_links = [app_list_links; extractBetween(txt_chunk{indxChunk}, '<li>', '</li>')];
            end
            %Extracts from the links, the URL and put them in a struct array
            app_url = extractBetween(app_list_links, '<a href="', '">');
            app.URL = [app.URL; app_url];
            %Extracts from the links, the name and put them in a struct array
            app.name = [app.name; extractBetween(app_list_links, '">', '</a>')];
            %Extracts from the links, the id and put them a struct array
            app.id = [app.id; extractBetween(app_list_links, '/id', '?mt=8">')];
            %Saves the category of each app
            N = size(app_url, 1);
            app.category = [app.category; repmat({categories(i)}, N, 1)];
            if (isempty(paginate_more) == 1)
                if (page == 1)  % No Next in the pagination
                    bandcontrol_no_next = 1;
                    pagination_data = extractBetween(html_data_let, 'list paginate', '</a></li></ul>');
                    if (isempty(pagination_data))   % Control is just 1 page
                        band = 1;
                    else
                        uper_pag = pagination_data{1};
                        final_page = str2double(uper_pag(end));
                    end 
                end 
                if (bandcontrol_no_next == 1)
                    if(cont_no_next == final_page)
                        bandcontrol_no_next = 0;
                        band = 1;
                    else 
                        cont_no_next  = cont_no_next + 1;
                    end
                else
                    band = 1;
                end  
            end
        end
    end
end

% Creates the datasets for each category
indxMedical = find(strcmp(categories(1), [app.category{:}]));
indxHF = find(strcmp(categories(2), [app.category{:}]));
% Medical dataset
M.URL = app.URL(indxMedical);
M.name = app.name(indxMedical);
M.id = app.id(indxMedical);
% Health and Fitness dataset
HnF.URL = app.URL(indxHF);
HnF.name = app.name(indxHF);
HnF.id = app.id(indxHF);

% Eliminates the duplicate apps
[uniqueM,indUM,indM] = unique(M.id,'stable');
[uniqueHnF,indUHF,indHF] = unique(HnF.id,'stable');
M.URL = M.URL(indUM);
M.id = M.id(indUM);
M.name = M.name(indUM);
HnF.URL = HnF.URL(indUHF);
HnF.id = HnF.id(indUHF);
HnF.name = HnF.name(indUHF);

[both,indm,indhf] = intersect(uniqueM,uniqueHnF,'stable');
catM = repmat("Medical",length(uniqueM),1);
catHF = repmat("Health and Fitness",length(uniqueHnF),1);
catM(indm) = "Both";
catHF(indhf) = [];

hnf = HnF;
hnf.URL(indhf) = [];
hnf.id(indhf) = [];
hnf.name(indhf) = [];

merged.URL = [M.URL;hnf.URL];
merged.id = [M.id;hnf.id];
merged.name = [M.name;hnf.name];
merged.category = [catM;catHF];

% Saves the results
save('merged.mat', 'merged')
save('M.mat', 'M')
save('HnF.mat', 'HnF')

% % Exports tables as excel files
% saveAsExcelFile(indxHF,HnF,'health_and_fitness');
% saveAsExcelFile(indxMedical,M,'medical');
% saveAsExcelFile((merged.URL)',merged,'merged');
%%
%__________________Feature Extraction_____________________%

vect=round((length(merged.URL)-1).*rand(5,1))+1; 
%vect is a vector containg random numbers, to extract the features for any 5 random apps in the list
% is the length of the app-1 because rand() generates random numbers from 0
% to 1, and since we don't want an index to be 0, we substract 1 to the
% length and add it at the end.
AppsFeatures = {};

for i=1:length(vect)
    url = merged.URL(vect(i));
    html_features= webread(url{:});% Reads the html code of the random app
    
    %Feature 1:  App ID 
    features.id=merged.id(vect(i)); 
    % Since we already have this information it takes it from the variable app.id
    
    %Feature 2: App Name
    features.name=merged.name(vect(i));
    % Since we already have this information it takes it from the variable app.name
    
    %Feature 3: App URL 
    features.URL=merged.URL(vect(i));
    % Since we already have this information it takes it from the variable app.URL
    
    %Feature 4: App Description (Unstructured text)
    temp_extract=extractBetween(html_features,'<div class="section__description">','</section>');
    % temporal chunck of code that allows to exctract the description from it
    features.description=extractBetween(temp_extract, '<p aria-label="', '" id=');
    
    %Feature5: Keywords
    features.keywords=extractBetween(html_features, '<meta name="keywords" content="','" id=');
    
    %Feature 6: Version
    features.version=extractBetween(html_features,'<p class="l-column small-6 medium-12 whats-new__latest__version">Version','</p>');
    
    %Feature 7: Age Rating
    temp_extract=extractBetween(html_features,'<dt class="information-list__item__term medium-valign-top l-column medium-3 large-2">Age Rating</dt>','<!---->');
    agerat=extractBetween(temp_extract,'large-6">','</dd>');
    agerat = agerat{:};
    nums = ['1','2','3','4','5','6','7','8','9','0','+'];
    indx = find(ismember(agerat,nums));
    agerat = agerat(indx(1):indx(end));
    % temporal chunck of code that allows to exctract the age rating from it
    features.agerat=agerat;
    
    %Feature 8: Language
    temp_extract=extractBetween(html_features,'<dt class="information-list__item__term medium-valign-top l-column medium-3 large-2">Languages</dt>','</div>');
    % temporal chunck of code that allows to exctract the language from it
    features.language=extractBetween(temp_extract,'<dd aria-label="','" id="');
    
    %Feature 9-11: Developer ID- Developer Name- Developer Webside
    temp_extract=extractBetween(html_features,'<h2 class="product-header__identity app-header__identity">','</h2>');
    % temporal chunck of code that allows to exctract all features related to the developer from it
    features.developerid=extractBetween(temp_extract,'id','?mt=8"');
    features.developername=extractBetween(temp_extract,'?mt=8">','</a>');
    features.developerURL=extractBetween(temp_extract,' <a class="link" href="','">');
    
    %Feature 12: Category (medical, health and fitness, or both)
    features.category = merged.category(vect(i));
    
    % Since we already have this information it takes it from the variable app.category
    % It depends on which file the app is being searched - 
    
    %Feature 13-14: Price (numbers only) and Currency
    temp_extract=extractBetween(html_features,'<dt class="information-list__item__term medium-valign-top l-column medium-3 large-2">Price</dt>','</div>');
    %temporal chunck of code that allows to exctract the price and currency from it
    temp_price=extractBetween(temp_extract,'<dd class="information-list__item__definition l-column medium-9 large-6">','</dd>');
    %temporal variable to save the price to the process it beacuse it may be a string saying "Free" or may have characters such as $,�,etc.
    features.pricecurrency='$';% currency is USD by default
    temp_price = temp_price{:};
    if(isequal(temp_price,'Free'))
        features.price=0;%if it is free the price is 0
        %if it is free the currency is still in USD by default
    else
        flag=false;
        temp_currency='$';
        %temporal variable to manage the currency
        
        for j=1:length(temp_price)
            if(flag==false)
                if(temp_price(j)<char(48) || temp_price(j)>char(57))% meaning that is not a number, thus is part of the currency
                    temp_currency= temp_price(1:j);
                    %the currency is equivalent to the characters of the price
                    %that have non-numerical values
                else
                    flag=true; % when the flag is true it means that we found the begining of the numerical values
                    %in the price varible.
                    temp_price=temp_price(j:end);% so the price variable takes only the numerical values.
                end
            end
         features.pricecurrency=temp_currency;
         features.price=str2double(temp_price);
         
        end
    end
    
    %Feature 15: Size in MB
    size_MB=char(extractBetween(html_features,'<dd class="information-list__item__definition l-column medium-9 large-6" aria-label="', ' megabytes">'));
    if (isnan(size_MB))
        size_MB='NaN';
    else
        features.size=str2double(size_MB);
    end
    
    %Feature 16: Last update date (DATE)
    temp_extract=extractBetween(html_features,'<div class="l-row whats-new__content">','<p class="l-column small-6 medium-12 whats-new__latest__version">Version');
    lastupdate = extractBetween(temp_extract,'class="" >','</time>');
    features.lastupdate = datetime(lastupdate{:});
        
    %Feature 17: Release date (DATE)
    reldate=extractBetween(html_features,',"releaseDate":"','","softwareInfo":{');
    features.reldate=datetime(reldate{:});
    
    %Rating presence control. If there isn't, it will set features as null.
    
    if(~contains(html_features,'<span class="we-customer-ratings__averages__display">'))
        features.avgcurrat='NaN';
        features.numcurus='NaN';
        features.avgallrat='NaN';
        features.numallus='NaN';
        features.perc5='NaN';
        features.perc4='NaN';
        features.perc3='NaN';
        features.perc2='NaN';
        features.perc1='NaN';
        
    else
        
        %Feature 18: Current version: average user ratings (NO TEXT, ONLY NUMBERS)
        features.avgcurrat=extractBetween(html_features,'{"@type":"AggregateRating","ratingValue":',',"reviewCount"');
        
        %Feature 19: Current version: number of user ratings (INTEGER)
        features.numcurus=extractBetween(html_features,',"reviewCount":','},"offers"');
        
        %Feature 20: All versions: average user ratings (NO TEXT, ONLY NUMBERS)
        features.avgallrat=features.avgcurrat;
        % The same value as in Current version
        % SHOULD THIS BE NULL, OR THE SAME VALUE?
        
        %Feature 21: All versions: number of user ratings (INTEGER)
        features.numallus=features.numcurus;
        % The same value as in Current version
        % SHOULD THIS BE NULL, OR THE SAME VALUE?
        
        %Feature 22: Number of user ratings with 5 stars(INTEGER)
        temp_perc=extractBetween(html_features,'<span class="we-star-bar-graph__stars we-star-bar-graph__stars--5"></span>','</div>');
        features.perc5=extractBetween(temp_perc,'width: ','%;">');
        
        %Feature 23: Number of user ratings with 4 stars(INTEGER)
        temp_perc=extractBetween(html_features,'<span class="we-star-bar-graph__stars we-star-bar-graph__stars--4"></span>','</div>');
        features.perc4=extractBetween(temp_perc,'width: ','%;">');
        
        %Feature 24: Number of user ratings with 3 stars(INTEGER)
        temp_perc=extractBetween(html_features,'<span class="we-star-bar-graph__stars we-star-bar-graph__stars--3"></span>','</div>');
        features.perc3=extractBetween(temp_perc,'width: ','%;">');
        
        %Feature 25: Number of user ratings with 2 stars(INTEGER)
        temp_perc=extractBetween(html_features,'<span class="we-star-bar-graph__stars we-star-bar-graph__stars--2"></span>','</div>');
        features.perc2=extractBetween(temp_perc,'width: ','%;">');
        
        %Feature 26: Number of user ratings with 1 stars(INTEGER)
        temp_perc=extractBetween(html_features,'<span class="we-star-bar-graph__stars "></span>','</div>');
        features.perc1=extractBetween(temp_perc,'width: ','%;">');
    end
    
    %Feature 27: Date Retrieved (set by user)
    features.retdate = date();
        
    AppsFeatures{i,1} = features;
end
