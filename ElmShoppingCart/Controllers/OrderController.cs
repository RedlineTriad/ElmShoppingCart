using ElmShoppingCart.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace ElmShoppingCart.Controllers
{
    [Route("api/[controller]")]
    [Authorize]
    [ApiController]
    public class OrderController : ControllerBase
    {
        private readonly AppDbContext context;
        private readonly UserManager<AppUser> userManager;

        public OrderController(AppDbContext context, UserManager<AppUser> userManager)
        {
            this.context = context;
            this.userManager = userManager;
        }

        // GET: api/Order
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrder()
        {
            return await context.Order.ToListAsync();
        }

        // GET: api/Order/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Order>> GetOrder(Guid id)
        {
            var order = await context.Order.FindAsync(id);

            return order ?? (ActionResult<Order>)NotFound();
        }

        // POST: api/Order
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        [HttpPost]
        public async Task<ActionResult<Order>> PostOrder(
            [Bind(new [] {
                nameof(Order.Amount),
                nameof(Order.Product)
            })]
            Order order)
        {
            order.Author = await userManager.GetUserAsync(User);
            order.CreationTime = DateTime.Now;
            context.Order.Add(order);
            await context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
        }

        // DELETE: api/Order/5
        [HttpDelete("{id}")]
        public async Task<ActionResult<Order>> DeleteOrder(Guid id)
        {
            var order = await context.Order.FindAsync(id);
            if (order == null)
            {
                return NotFound();
            }

            if(order.Author != await userManager.GetUserAsync(User))
            {
                return Unauthorized();
            }

            context.Order.Remove(order);
            await context.SaveChangesAsync();

            return order;
        }
    }
}