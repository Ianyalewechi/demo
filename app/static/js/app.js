function toggleMenu() {
    const menu = document.getElementById("mobileMenu");

    if (menu) {
        menu.classList.toggle("open");
    }
}

document.addEventListener("DOMContentLoaded", function () {
    const mobileLinks = document.querySelectorAll("#mobileMenu a");

    mobileLinks.forEach(function (link) {
        link.addEventListener("click", function () {
            const menu = document.getElementById("mobileMenu");

            if (menu) {
                menu.classList.remove("open");
            }
        });
    });
});