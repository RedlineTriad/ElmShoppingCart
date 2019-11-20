using AutoMapper;
using ElmShoppingCart.Models;
using ElmShoppingCart.Models.ViewModel;
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
        private readonly IMapper mapper;

        public OrderController(AppDbContext context, UserManager<AppUser> userManager, IMapper mapper)
        {
            this.context = context;
            this.userManager = userManager;
            this.mapper = mapper;
        }

        // GET: api/Order
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrder()
        {
            return await context.Order.ToListAsync();
        }

        // GET: api/Order/5
        [HttpGet("{id}")]
        public async Task<ActionResult<OrderViewModel>> GetOrder(Guid id)
        {
            var order = await context.Order.FindAsync(id);

            return mapper.Map<OrderViewModel>(order) ?? (ActionResult<OrderViewModel>)NotFound();
        }

        // POST: api/Order
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for
        // more details see https://aka.ms/RazorPagesCRUD.
        [HttpPost]
        public async Task<ActionResult<Order>> PostOrder(CreateOrderViewModel orderViewModel)
        {
            var order = mapper.Map<Order>(orderViewModel);
            order.Author = await userManager.GetUserAsync(User);
            order.CreationTime = DateTime.Now;
            context.Order.Add(order);
            await context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, mapper.Map<OrderViewModel>(order));
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

            if(order.AuthorId != (await userManager.GetUserAsync(User))?.Id)
            {
                return Unauthorized();
            }

            context.Order.Remove(order);
            await context.SaveChangesAsync();

            return order;
        }
    }
}