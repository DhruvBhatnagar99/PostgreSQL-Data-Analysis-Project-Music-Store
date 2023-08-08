/* Q1: Who is the senior most employee based on job title? */
SELECT first_name,last_name FROM employee ORDER BY levels DESC LIMIT 1;

/* Q2: Which countries have the most Invoices? */
SELECT COUNT(*) AS total_invoices,billing_country FROM invoice GROUP BY billing_country ORDER BY total_invoices DESC;

/* Q3: What are top 3 values of total invoice? */
SELECT total FROM invoice ORDER BY total DESC LIMIT 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */
SELECT billing_city,SUM(total) AS total_invoice FROM invoice GROUP BY billing_city ORDER BY total_invoice DESC LIMIT 1;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT customer.customer_id,customer.first_name,customer.last_name,SUM(invoice.total) AS total_spent
FROM customer JOIN invoice
ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total_spent DESC
LIMIT 1;

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */
SELECT DISTINCT customer.email,customer.first_name,customer.last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

/* Method 2 */

SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoiceline ON invoiceline.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoiceline.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;

/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */
SELECT artist.artist_id,artist.name,COUNT(artist.artist_id) AS no_of_songs
FROM artist 
JOIN album ON artist.artist_id = album.artist_id
JOIN track ON album.album_id = track.album_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY no_of_songs DESC
LIMIT 10;

/* Q8: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */
SELECT name,milliseconds FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) AS average_track_length FROM track)
ORDER BY milliseconds DESC;


/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */
Using CTE:
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id,artist.name AS artist_name,SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON invoice_line.track_id = track.track_id
	JOIN album ON track.album_id = album.album_id
	JOIN artist ON album.artist_id = artist.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT customer.customer_id,customer.first_name,customer.last_name,best_selling_artist.artist_name,SUM(invoice_line.unit_price*invoice_line.quantity) AS money_spent
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN album ON track.album_id = album.album_id
JOIN best_selling_artist ON album.artist_id = best_selling_artist.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Method 1: Using CTE */
WITH popular_genre AS (
	SELECT COUNT(invoice_line.quantity) AS purchases,customer.country,genre.name,genre.genre_id,
		ROW_NUMBER() OVER (PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
	FROM customer
	JOIN invoice ON customer.customer_id = invoice.customer_id
	JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
	JOIN track ON invoice_line.track_id = track.track_id
	JOIN genre ON track.genre_id = genre.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC,1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;


/* Method 2: : Using Recursive */
Using Recursive:
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre,customer.country,genre.name,genre.genre_id
		FROM customer
		JOIN invoice ON customer.customer_id = invoice.customer_id
		JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
		JOIN track ON invoice_line.track_id = track.track_id
		JOIN genre ON track.genre_id = genre.genre_id
		GROUP BY 2,3,4
		ORDER BY 2 
	),
	max_genre_per_country AS(SELECT MAX(purchases_per_genre) AS max_genre_number,country
							FROM sales_per_country
							GROUP BY 2
							ORDER BY 2)

SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

/* Q11: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */


/* Method 1: using CTE */
WITH customer_with_country AS (
	SELECT customer.customer_id,customer.first_name,customer.last_name,invoice.billing_country,SUM(total),
	ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
	FROM customer 
	JOIN invoice ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC,5 DESC)
SELECT * FROM customer_with_country WHERE RowNo <= 1;


/* Method 2: Using Recursive */
WITH RECURSIVE
	customer_with_country AS (
	SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
	FROM customer 
	JOIN invoice ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 1 ASC,5 DESC),
	
	country_max_spending AS(
	SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customer_with_country GROUP BY billing_country)

SELECT customer_with_country.billing_country,customer_with_country.total_spending,customer_with_country.first_name,customer_with_country.last_name,customer_with_country.customer_id
FROM customer_with_country 
JOIN country_max_spending 
ON customer_with_country.billing_country = country_max_spending.billing_country
WHERE customer_with_country.total_spending = country_max_spending.max_spending
ORDER BY 1;




