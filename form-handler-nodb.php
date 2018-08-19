<?php
// Emails form data to you and the person submitting the form
// This version requires no database.
// Set your email below
$myemail = "profor321@gmail.com"; // Replace with your email, please

// Receive and sanitize input
$name = $_POST['name'];
$email = $_POST['email'];
$phone = $_POST['phone'];
$message = $_POST['message'];

// set up email
$msg = "New contact form submission!\nName: " . $name . "\nEmail: " . $email . "\nPhone: " . $phone . "\nEmail: " . $email;
$msg = wordwrap($msg,70);
mail($myemail,"New Form Submission",$msg);
mail($email,"Thank you for your form submission",$msg);

$page_title = 'Thank You';
include ('includes/header.html');
?>

    <div class="container">

        <div class="row">
            <div class="box">
                <div class="col-lg-12">
                    <hr>
                    <h2 class="intro-text text-center">We will get back to you soon
                        <strong>Thank you</strong>
                    </h2>
                    <hr>
                    <p>Thank you for contacting Profor. We appreciate your interest in us and we will get back to
                     you in the next 24 hours.</p>
                </div>
            </div>
        </div>
        
    </div>

<?php
include ('includes/footer.html');
?>
